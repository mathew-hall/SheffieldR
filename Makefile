
.PHONY: all clean pull

%.html: %.md
	Rscript -e "require(knitr); require(markdown); markdownToHTML('$<', '$@', options=c('use_xhtml', 'base64_images'));"
	
	

%.md: %.Rmd TB_Burden_Data.csv
	SQL_FILE=$< Rscript -e "require(knitr); require(markdown); knit('$<', '$@');"
	
TB_Burden_Data.csv:
	curl https://extranet.who.int/tme/generateCSV.asp?ds=estimates -o TB_Burden_Data.csv
	
all: $(addsuffix .html, $(basename $(wildcard *.Rmd)))
	
clean:
	rm *.html
