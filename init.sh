#!/bin/bash

echo "Importing config.ini..."
source <(grep = config.ini)
vars=($(grep -aoP ".*(?=\=)" config.ini))
for var in ${vars[@]}; do
    if [ -z ${!var} ]; then
        echo "$var is unset. Edit config.ini"
        exit 1
    fi
done

echo "Creating venv..."
mv project $PROJECT_NAME
cd $PROJECT_NAME
python3 -mvenv venv 2>/dev/null || py -mvenv venv                        #<-- hack for windows
source venv/bin/activate 2>/dev/null || source venv/Scripts/activate     #<-- hack for windows
pip3 install --quiet -r requirements.txt

echo "Renaming django project..."
python manage.py rename project $PROJECT_NAME

echo "Seting up configs..."
cd ..
for file in `ls deploy`; do
    for var in ${vars[@]}; do
        sed -i "s/$var/${!var}/g" deploy/$file
    done    
done    

echo "Deploying on remote host..."
scp -r deploy $REMOTE_USER@$REMOTE_HOST:~
scp -r deploy/update.sh $REMOTE_SUER@$REMOTE_HOST:~
scp -r config.ini $REMOTE_USER@$REMOTE_HOST:~/deploy/
ssh $REMOTE_USER@$REMOTE_HOST:~ "bash deploy/deploy.sh"

echo "Removing temp files..."
rm -rf deploy config.ini init.sh README.md

echo "Creating new README..."
echo "# $PROJECT_NAME" > README.md

echo "Creating git..."
rm -rf .git
git init -q
git add -A -q
git commit -m -q "Initial commit"
git remote add origin $GITHUB_URL
