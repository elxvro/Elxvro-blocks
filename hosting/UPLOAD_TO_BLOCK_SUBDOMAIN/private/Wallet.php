<?php
declare(strict_types=1);
final class Wallet {
    public const SHOP = [
        'undo_3'=>[120,['undo'=>3]], 'refresh_3'=>[120,['refresh'=>3]],
        'special_3'=>[180,['special'=>3]], 'power_bundle'=>[300,['undo'=>5,'refresh'=>5,'special'=>2]],
        'theme:night'=>[300,['theme:night'=>1]], 'theme:marble'=>[500,['theme:marble'=>1]],
        'theme:fire'=>[700,['theme:fire'=>1]], 'theme:nature'=>[700,['theme:nature'=>1]],
        'theme:aurora'=>[1000,['theme:aurora'=>1]],
    ];
    public function __construct(private PDO $db,private array $config) {}
    private function query(string $sql,array $args=[]): PDOStatement {$s=$this->db->prepare($sql);$s->execute($args);return $s;}
    private function lock(string $sub): void {
        // Duplicate-key UPDATE takes an exclusive lock; INSERT IGNORE would
        // take shared locks that can deadlock when both requests upgrade them.
        $this->query('INSERT INTO player_wallets (google_sub) VALUES (?) ON DUPLICATE KEY UPDATE google_sub=VALUES(google_sub)',[$sub]);
        $this->query('SELECT google_sub FROM player_wallets WHERE google_sub=? FOR UPDATE',[$sub]);
        $this->query('INSERT IGNORE INTO billing_accounts (google_sub) VALUES (?)',[$sub]);
    }
    private function transaction(callable $f): mixed {
        // Retry only a fully rolled-back database transaction. Callbacks have
        // no external effects; purchase tokens and operation IDs remain stable.
        for($attempt=0;;$attempt++){
            $this->db->beginTransaction();
            try {$r=$f();$this->db->commit();return $r;}
            catch(Throwable $e){
                if($this->db->inTransaction())$this->db->rollBack();
                if($e instanceof PDOException && $e->getCode()==='40001' && $attempt<3){usleep(random_int(10000,50000));continue;}
                throw $e;
            }
        }
    }
    public function tokenId(string $token): string {
        $key=$this->config['purchase_token_hmac_secret']??'';
        if(strlen($key)<32||str_contains($key,'REPLACE'))throw new BillingException(503,'token_key_unconfigured');
        return hash_hmac('sha256',$token,$key);
    }
    private function encryptionKey(): string {
        $key=base64_decode($this->config['token_encryption_key']??'',true);
        if(!is_string($key)||strlen($key)!==32)throw new BillingException(503,'encryption_key_unconfigured');
        return $key;
    }
    private function encrypt(string $token,string $id): string {
        $iv=random_bytes(12);$cipher=openssl_encrypt($token,'aes-256-gcm',$this->encryptionKey(),OPENSSL_RAW_DATA,$iv,$tag,$id);
        if($cipher===false)throw new RuntimeException('encryption_failed');
        return base64_encode($iv.$tag.$cipher);
    }
    public function decrypt(string $encoded,string $id): string {
        $raw=base64_decode($encoded,true);
        if($raw===false||strlen($raw)<29)throw new RuntimeException('invalid_ciphertext');
        $token=openssl_decrypt(substr($raw,28),'aes-256-gcm',$this->encryptionKey(),OPENSSL_RAW_DATA,substr($raw,0,12),substr($raw,12,16),$id);
        if($token===false)throw new RuntimeException('invalid_ciphertext');return $token;
    }
    public function snapshot(string $sub): array {
        if(!$this->db->inTransaction())return $this->transaction(function()use($sub){$this->lock($sub);return $this->snapshot($sub);});
        $w=$this->query('SELECT w.balance,w.supporter,COALESCE(a.debt,0) debt,COALESCE(a.revision,0) revision FROM player_wallets w LEFT JOIN billing_accounts a USING(google_sub) WHERE google_sub=?',[$sub])->fetch();
        $inventory=['undo'=>0,'refresh'=>0,'special'=>0];$themes=[];
        foreach($this->query('SELECT sku,quantity FROM billing_inventory WHERE google_sub=?',[$sub])->fetchAll() as $r){
            if(str_starts_with($r['sku'],'theme:')){if((int)$r['quantity']>0)$themes[]=substr($r['sku'],6);}
            else $inventory[$r['sku']]=(int)$r['quantity'];
        }
        $debt=(int)($w['debt']??0);
        return ['protocol'=>3,'source'=>'verified_purchases','balance'=>(int)($w['balance']??0),'supporter'=>(bool)($w['supporter']??false),
          'debt'=>$debt,'revision'=>(int)($w['revision']??0),'inventory'=>$debt>0?['undo'=>0,'refresh'=>0,'special'=>0]:$inventory,'themes'=>$debt>0?[]:$themes];
    }
    private function changed(string $sub): void {$this->query('UPDATE billing_accounts SET revision=revision+1 WHERE google_sub=?',[$sub]);}
    public function grant(string $sub,string $productId,string $token,string $orderId,bool $alreadyConsumed=false): array {
        $product=Products::get($productId);$id=$this->tokenId($token);
        if(strlen($orderId)>128)throw new BillingException(422,'invalid_order_id');
        return $this->transaction(function()use($sub,$productId,$token,$orderId,$product,$id,$alreadyConsumed){
            $this->lock($sub);
            $prior=$this->query('SELECT p.*,r.revoked FROM play_purchases p LEFT JOIN billing_receipts r USING(token_hmac) WHERE p.token_hmac=?',[$id])->fetch();
            if($prior){
                if($prior['google_sub']!==$sub||$prior['product_id']!==$productId)throw new BillingException(409,'purchase_owner_mismatch');
                if($prior['revoked'])throw new BillingException(409,'purchase_revoked');
                return ['alreadyGranted'=>true]+$this->snapshot($sub);
            }
            if($alreadyConsumed)throw new BillingException(409,'untracked_consumed_purchase');
            if($orderId!==''&&$this->query('SELECT token_hmac FROM play_purchases WHERE order_id=? LIMIT 1',[$orderId])->fetch())throw new BillingException(409,'order_already_used');
            $this->query('INSERT INTO play_purchases(token_hmac,google_sub,product_id,order_id,coins_granted) VALUES(?,?,?,?,?)',[$id,$sub,$productId,$orderId?:null,$product['coins']]);
            try{$this->query('INSERT INTO billing_receipts(token_hmac,order_id,encrypted_token) VALUES(?,?,?)',[$id,$orderId?:null,$this->encrypt($token,$id)]);}
            catch(PDOException $e){if($e->getCode()==='23000')throw new BillingException(409,'order_already_used');throw $e;}
            $debt=$this->snapshot($sub)['debt'];$offset=min($debt,$product['coins']);
            $this->query('UPDATE billing_accounts SET debt=debt-? WHERE google_sub=?',[$offset,$sub]);
            $this->query('UPDATE player_wallets SET balance=balance+?,supporter=GREATEST(supporter,?) WHERE google_sub=?',[$product['coins']-$offset,(int)$product['supporter'],$sub]);
            $this->changed($sub);return ['alreadyGranted'=>false]+$this->snapshot($sub);
        });
    }
    private function operation(string $sub,string $id,string $action): bool {
        if(!preg_match('/^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/D',$id))throw new BillingException(400,'invalid_operation_id');
        $old=$this->query('SELECT action FROM billing_operations WHERE google_sub=? AND operation_id=?',[$sub,$id])->fetch();
        if($old){if($old['action']!==$action)throw new BillingException(409,'operation_conflict');return false;}
        $this->query('INSERT INTO billing_operations(google_sub,operation_id,action) VALUES(?,?,?)',[$sub,$id,$action]);return true;
    }
    public function spend(string $sub,string $sku,string $operation): array {
        $offer=self::SHOP[$sku]??throw new BillingException(400,'unknown_sku');
        return $this->transaction(function()use($sub,$sku,$operation,$offer){
            $this->lock($sub);
            if(!$this->operation($sub,$operation,'buy:'.$sku))return $this->snapshot($sub);
            $w=$this->snapshot($sub);if($w['debt']>0)throw new BillingException(409,'wallet_debt');
            if(str_starts_with($sku,'theme:')&&in_array(substr($sku,6),$w['themes'],true))return $w;
            if($w['balance']<$offer[0])throw new BillingException(409,'insufficient_balance');
            $this->query('UPDATE player_wallets SET balance=balance-? WHERE google_sub=?',[$offer[0],$sub]);
            foreach($offer[1] as $item=>$n)$this->query('INSERT INTO billing_inventory(google_sub,sku,quantity) VALUES(?,?,?) ON DUPLICATE KEY UPDATE quantity=quantity+VALUES(quantity)',[$sub,$item,$n]);
            $this->changed($sub);return $this->snapshot($sub);
        });
    }
    public function useItem(string $sub,string $sku,string $operation): array {
        if(!in_array($sku,['undo','refresh','special'],true))throw new BillingException(400,'unknown_item');
        return $this->transaction(function()use($sub,$sku,$operation){
            $this->lock($sub);if(!$this->operation($sub,$operation,'use:'.$sku))return $this->snapshot($sub);
            $w=$this->snapshot($sub);if($w['debt']>0)throw new BillingException(409,'wallet_debt');
            if($w['inventory'][$sku]<1)throw new BillingException(409,'insufficient_inventory');
            $this->query('UPDATE billing_inventory SET quantity=quantity-1 WHERE google_sub=? AND sku=?',[$sub,$sku]);
            $this->changed($sub);return $this->snapshot($sub);
        });
    }
    public function markFinalized(string $token): void {
        $this->query('UPDATE billing_receipts SET finalized=1,checked_at=CURRENT_TIMESTAMP WHERE token_hmac=?',[$this->tokenId($token)]);
    }
    public function revoke(string $token): void {
        $id=$this->tokenId($token);$p=$this->query('SELECT * FROM play_purchases WHERE token_hmac=?',[$id])->fetch();if(!$p)return;
        $this->transaction(function()use($p,$id){
            $sub=$p['google_sub'];$this->lock($sub);
            $r=$this->query('SELECT revoked FROM billing_receipts WHERE token_hmac=? FOR UPDATE',[$id])->fetch();
            if($r&&$r['revoked'])return;
            // Legacy purchases also get a tombstone; they must never be granted again.
            $this->query("INSERT INTO billing_receipts(token_hmac,order_id,encrypted_token,revoked) VALUES(?,NULL,'',1) ON DUPLICATE KEY UPDATE revoked=1",[$id]);
            $w=$this->snapshot($sub);$coins=(int)$p['coins_granted'];$deduct=min($w['balance'],$coins);
            $this->query('UPDATE player_wallets SET balance=balance-? WHERE google_sub=?',[$deduct,$sub]);
            $this->query('UPDATE billing_accounts SET debt=debt+? WHERE google_sub=?',[$coins-$deduct,$sub]);
            if($p['product_id']==='elxvro_supporter_badge'){
                $other=$this->query("SELECT COUNT(*) FROM play_purchases p LEFT JOIN billing_receipts r USING(token_hmac) WHERE p.google_sub=? AND p.product_id='elxvro_supporter_badge' AND COALESCE(r.revoked,0)=0",[$sub])->fetchColumn();
                $this->query('UPDATE player_wallets SET supporter=? WHERE google_sub=?',[(int)($other>0),$sub]);
            }
            $this->changed($sub);
        });
    }
}
