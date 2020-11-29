mkdir -p templates
cd ./app
make 
cd ..
cp app/dist/* templates
