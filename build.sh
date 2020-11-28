mkdir -p templates
cd ./app
make upload_page
make view_all_page
cd ..
cp app/dist/upload.html templates
cp app/dist/view_all.html templates
