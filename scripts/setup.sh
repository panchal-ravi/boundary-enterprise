DATETIME=$(date +'%d%m%Y_%H%M%S')
TFDIR=$1
if [ ! -d "$TFDIR/generated" ]; then
  mkdir $TFDIR/generated
fi

cp $TFDIR/generated/vault_token  $TFDIR/generated/vault_token_$DATETIME 
echo '' > $TFDIR/generated/vault_token

