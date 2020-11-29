
all: upload_page view_all_page calendar

upload_page:
	elm make src/Upload.elm
	mkdir -p dist
	mv index.html dist/upload.html

view_all_page:
	elm make src/ViewAll.elm
	mkdir -p dist
	mv index.html dist/view_all.html

calendar: 
	elm make src/Calendar.elm
	mkdir -p dist
	mv index.html dist/calendar.html
