<?php
declare(strict_types=1);
require __DIR__.'/private/bootstrap.php';
// Paid coins were retired; preserve old rows but reject all paid spending.
json_response(410,['error'=>'paid_coin_wallet_retired']);
