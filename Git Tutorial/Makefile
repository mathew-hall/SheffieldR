.PHONY: clean
	
tutorial.pdf: tutorial.html
	pandoc -s tutorial.html -o tutorial.pdf
	
tutorial.html: tutorial.md
	Rscript -e "require(knitr); require(markdown); markdownToHTML('$<', '$@', options=c('use_xhtml', 'base64_images'));"
	
tutorial.md: tutorial.Rmd
	Rscript -e "require(knitr); require(markdown); knit('tutorial.Rmd', 'tutorial.md');"
	
	
clean:
	rm tutorial.html
	rm tutorial.md
	rm tutorial.pdf