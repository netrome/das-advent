mkdir -p templates
cd ./app
make upload_page
cd ..
cp app/dist/upload.html templates/upload.html
