
概要
-------

別のサブスクリプション同士でゾーン間でPingを行い、ゾーン番号がサブスクリプション毎に異なる事をレイテンシから推測するためのコードとか。

- create-vm.bicep: 指定したリソースグループにVNET, NetworkSecurityGroupを作成、ゾーン毎にVM,Public IP、計3つを作成する。
- ssh-ping-test.sh: 各VMにSSH接続し、各VMにPingを飛ばし、ログを記録するスクリプト


準備
-------

- Azure CLI
- Git for windows (Git Bash, perlを利用する)


作業
--------

### サブスクリプションを選ぶ

```
az account list --output table
```

2つ選んで変数に控えておく

```
SUBSCRIPTION_1=xxxxxxxxxxx
SUBSCRIPTION_2=xxxxxxxxxxx
```

### parameters.jsonを修正する

sourceAddressPrefix, vmPassword, vmUsernameを修正

### リソース作成する

```

RESOURCE_GROUP_NAME='rg-fukasawah-example-2'

# SUBSCRIPTION_1: Create ResourceGroup
az group create --subscription "$SUBSCRIPTION_1" --name "$RESOURCE_GROUP_NAME" --location "japaneast" 

# SUBSCRIPTION_1: Deploy
az group deployment create --subscription "$SUBSCRIPTION_1" --resource-group "$RESOURCE_GROUP_NAME"  --template-file "create-vm.bicep" --parameters @parameters.json


# SUBSCRIPTION_2: Create ResourceGroup
az group create --subscription "$SUBSCRIPTION_2" --name "$RESOURCE_GROUP_NAME" --location "japaneast" 

# SUBSCRIPTION_2: Deploy
az group deployment create --subscription "$SUBSCRIPTION_2" --resource-group "$RESOURCE_GROUP_NAME"  --template-file "create-vm.bicep" --parameters @parameters.json
```

実行後、outputにVM毎にホスト名が得られる。

### ssh-ping-test.sh を修正する

USERNAME, HOSTSの値を修正する。

### ssh-ping-test.sh を実行する

```
bash ssh-ping-test.sh
```

※都度ID/PASS入力

`host名.log`が出来上がる

### 結果ファイルからmin値取り出す

上から書き換えたssh-ping-test.shのHOSTSの順序

```
for file in *.log; do echo $file; grep 'min/avg/max/mdev' "$file" | perl -ple 's/.* = ([^\/]+).*/$1/' ; done
```

あとは値を切り貼りしていい感じにする。