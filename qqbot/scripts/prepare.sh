_ID=39154
_NAME=qq
groupadd -g "$_ID" "$_NAME"
useradd --create-home --gid "$_ID" --no-user-group --uid "$_ID" "$_NAME"

mkdir /home/qq/.cache /home/qq/.config/QQ
chown -R qq:qq /home/qq
