<?php
declare(strict_types=1);
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
require __DIR__.'/v0283.php';
try{
 foreach(['curl','openssl','pdo_mysql'] as $ext)if(!extension_loaded($ext))throw new RuntimeException('missing_extension');
 $c=billing_config();$db=api_db($c);
 $file=$c['service_account_json']??'';
 if(!is_string($file)||!is_file($file))throw new RuntimeException('service_account_missing');
 $sa=json_decode((string)file_get_contents($file),true,512,JSON_THROW_ON_ERROR);
 if(($sa['type']??'')!=='service_account'||empty($sa['project_id'])||empty($sa['client_email'])||empty($sa['private_key']))throw new RuntimeException('invalid_service_account');
 if(!openssl_pkey_get_private($sa['private_key']))throw new RuntimeException('invalid_private_key');
 $key=base64_decode($c['token_encryption_key']??'',true);
 if(!is_string($key)||strlen($key)!==32)throw new RuntimeException('invalid_encryption_key');
 (new Wallet($db,$c))->tokenId('configuration-self-check');
 $db->query('SELECT finalized FROM billing_receipts LIMIT 0');
 echo "PASS local PHP, database schema and private credential format\n";
 if(in_array('--google',$argv,true)){(new GoogleApi($c))->voided(null);echo "PASS Google OAuth and Play purchase API access\n";}
 echo worker_healthy($db)?"PASS reconciliation heartbeat\n":"PENDING reconciliation heartbeat\n";
 echo "No purchase was created; checkout settings unchanged.\n";
}catch(Throwable $e){fwrite(STDERR,'Setup check failed: '.get_class($e).". Check configuration privately; no secrets printed.\n");exit(1);}
