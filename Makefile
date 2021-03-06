SFUSER=rahtz
JING=jing
TRANG=trang
SAXON=saxon
SAXON_ARGS=-ext:on

DIRS=bibtex common docx dtd docbook epub epub3 fo html html5 json latex latex nlm odd odds odt pdf profiles/default rdf relaxng rnc slides tbx tcp tite tools txt html xsd xlsx pdf

SCRIPTS=docbooktotei docxtotei odttotei transformtei tcptotei xlsxtotei \
	teitodocx 	teitodtd 	teitoepub \
	teitoepub3 	teitofo 	teitohtml \
	teitohtml5 	teitojson 	teitolatex \
	teitoodt 	teitordf 	teitorelaxng \
	teitornc 	teitoslides 	teitotxt \
	teitoxsd	teitopdf	teitobibtex teitodocbook teitoodd
PREFIX=/usr
OXY=/usr/share/oxygen
DOCTARGETS= \
	latex/latex.xsl \
	html/html.xsl \
	fo/fo.xsl \
	tcp/tcp2tei.xsl \
	odds/odd2odd.xsl \
	odds/odd2relax.xsl \
	odds/odd2dtd.xsl \
	slides/teihtml-slides.xsl \
	slides/teilatex-slides.xsl \
	profiles/default/csv/from.xsl		\
	profiles/default/csv/to.xsl	\
	profiles/default/docbook/from.xsl	\
	profiles/default/docx/from.xsl \
	profiles/default/docx/to.xsl \
	profiles/default/dtd/to.xsl	\
	profiles/default/epub/to.xsl	\
	profiles/default/fo/to.xsl	\
	profiles/default/html/to.xsl \
	profiles/default/latex/to.xsl \
	profiles/default/lite/to.xsl \
	profiles/default/odt/from.xsl \
	profiles/default/odt/to.xsl \
	profiles/default/p4/from.xsl \
	profiles/default/relaxng/to.xsl	

PROFILEDOCTARGETS=\
	profiles/enrich/docx/from.xsl \
	profiles/enrich/docx/to.xsl \
	profiles/enrich/fo/to.xsl \
	profiles/enrich/html/to.xsl \
	profiles/enrich/latex/to.xsl 

.PHONY: doc release common profiles

default: check test release

check:
	@echo Checking you have running XML tools and Perl before trying to run transform...
	@echo -n Perl: 
	@which perl || exit 1
	@echo -n xmllint: 
	@which xmllint || exit 1
	@echo -n trang: 
	@which ${TRANG} || exit 1
	@echo -n jing: 
	@which ${JING} || exit 1
	@echo -n saxon: 
	@which ${SAXON} || exit 1

v:
	perl -p -i -e "s+AppVersion.*/AppVersion+AppVersion>`cat VERSION`</AppVersion+" docx/to/application.xsl

p5:
	@echo BUILD Build for P5, XSLT 2.0
	test -d release/p5 || mkdir -p release/p5/xml/tei/stylesheet/
	for i in  ${DIRS} ; do \
		tar cf - --exclude .svn $$i | (cd release/p5/xml/tei/stylesheet; tar xf - ); \
	done


common: names
	@echo BUILD Build for P5, common files and documentation
	test -d release/common/xml/tei/stylesheet || mkdir -p release/common/xml/tei/stylesheet
	cp names.xml catalog.xml VERSION *.css i18n.xml release/common/xml/tei/stylesheet

names:
	saxon -it:main tools/getnames.xsl > names.xml

profiles: 
	@echo BUILD Build for P5, profiles
	test -d release/profiles/xml/tei/stylesheet || mkdir -p release/profiles/xml/tei/stylesheet
	tar cf - --exclude .svn profiles | (cd release/profiles/xml/tei/stylesheet; tar xf - )

doc: oxygendoc
	test -d release/common/doc/tei-xsl || mkdir -p release/common/doc/tei-xsl
	saxon -o:doc/index.xml doc/teixsl.xml doc/param.xsl 
	saxon -o:doc/style.xml doc/teixsl.xml  doc/paramform.xsl 
	saxon -o:release/common/doc/tei-xsl/index.html doc/index.xml profiles/tei/html5/to.xsl cssFile=tei.css 
	saxon -o:release/common/doc/tei-xsl/style.html doc/style.xml  profiles/default/html/to.xsl 
	cp doc/*.png doc/teixsl.xml doc/style.xml release/common/doc/tei-xsl
	cp VERSION tei.css ChangeLog LICENCE release/common/doc/tei-xsl

oxygendoc:
	@echo text for existence of file $(OXY)/stylesheetDocumentation.sh
	-test -f $(OXY)/stylesheetDocumentation.sh && for i in ${DOCTARGETS}; do echo process doc for $$i; export ODIR=release/common/doc/tei-xsl/`dirname $$i`; ${OXY}/stylesheetDocumentation.sh $$i -cfg:doc/oxydoc.cfg; (cd `dirname $$i`; tar cf - release) | tar xf -; rm -rf `dirname $$i`/release; done

teioo.jar:
	(cd odt;  mkdir TEIP5; saxon -o:TEIP5/teitoodt.xsl -s:teitoodt.xsl expandxsl.xsl ; cp odttotei.xsl TEIP5.ott teilite.dtd TEIP5; jar cf ../teioo.jar TEIP5 TypeDetection.xcu ; rm -rf TEIP5)

test: clean p5 common names debversion
	@echo BUILD Run tests
	(cd Test; make)

dist: clean release
	-rm tei-xsl-`cat VERSION`.zip
	(cd release/common; zip -r -q ../../tei-xsl-`cat ../../VERSION`.zip .)
	(cd release/p5;     zip -r -q ../../tei-xsl-`cat ../../VERSION`.zip .)
	(cd release/profiles;    zip -r -q ../../tei-xsl-`cat ../../VERSION`.zip .)
	-rm -rf dist
	mkdir dist
	(cd release/p5; tar cf - .)       | (cd dist; tar xf  -)
	(cd release/profiles; tar cf - .) | (cd dist; tar xf  -)
	(cd release/common/; tar cf - .)  | (cd dist; tar xf -)

release: common doc oxygendoc p5 profiles

installp5: p5 teioo.jar
	mkdir -p ${PREFIX}/share/xml/tei/stylesheet
	cp teioo.jar ${PREFIX}/share/xml/tei/stylesheet
	(cd release/p5; tar cf - .) | (cd ${PREFIX}/share; tar xf  -)
	mkdir -p ${PREFIX}/bin
	for i in $(SCRIPTS); do \
	  cp $$i ${PREFIX}/bin/$$i; \
	  chmod 755 ${PREFIX}/bin/$$i; \
	  perl -p -i -e 's+^APPHOME=.*+APPHOME=/usr/share/xml/tei/stylesheet+' ${PREFIX}/bin/$$i; \
	done

installprofiles:
	test -d release/profiles || mkdir -p release/profiles/xml/tei/stylesheet/
	mkdir -p ${PREFIX}/share/xml/
	mkdir -p ${PREFIX}/share/doc/
	tar cf - --exclude .svn --exclude default profiles | (cd release/profiles/xml/tei/stylesheet; tar xf - )
	(cd release/profiles; tar cf - .) | (cd ${PREFIX}/share; tar xf  -)
	@echo text for existence of file $(OXY)/stylesheetDocumentation.sh
	-test -f $(OXY) && for i in ${PROFILEDOCTARGETS}; do echo process doc for $$i; export ODIR=release/profiles/doc/tei-p5-xslprofiles/`dirname $$i`; ${OXY}/stylesheetDocumentation.sh $$i -cfg:doc/oxydoc.cfg; (cd `dirname $$i`; tar cf - release) | tar xf -; rm -rf `dirname $$i`/release; done && \
	(cd release/profiles/doc; tar cf - .) | (cd ${PREFIX}/share/doc; tar xf -)

installcommon: doc common
	mkdir -p ${PREFIX}/lib/cgi-bin
	cp doc/stylebear ${PREFIX}/lib/cgi-bin/stylebear
	chmod 755 ${PREFIX}/lib/cgi-bin/stylebear
	mkdir -p ${PREFIX}/share/doc/
	mkdir -p ${PREFIX}/share/xml/
	(cd release/common/doc; tar cf - .) | (cd ${PREFIX}/share/doc; tar xf -)
	(cd release/common/xml; tar cf - .) | (cd ${PREFIX}/share/xml; tar xf -)

install: doc installp5 installprofiles installcommon 

debversion:
	sh ./mydch debian-tei-xsl/debian/changelog

deb: debversion
	@echo BUILD Make Debian packages
	rm -f tei*xsl*_*deb
	rm -f tei*xsl*_*changes
	rm -f tei*xsl*_*build
	(cd debian-tei-xsl; debclean;debuild --no-lintian  -nc -b -i.svn -I.svn -uc -us)

sfupload:
	rsync -e ssh tei-xsl-`cat VERSION`.zip ${SFUSER},tei@frs.sourceforge.net:/home/frs/project/t/te/tei/Stylesheets

log:
	(LastDate=`head -1 ChangeLog | awk '{print $$1}'`; \
	echo changes since $$LastDate; \
	./git-to-changelog --since=$$LastDate > newchanges)
	mv ChangeLog oldchanges
	cat newchanges oldchanges > ChangeLog
	rm newchanges oldchanges

clean:
	echo "" > test~
	rm -f profile1.html profile2.html profile.xml
	find . -name "*~"  | xargs rm
	rm -f tei-xsl-*.zip	
	rm -rf tei-xsl_*
	rm -f doc/stylebear doc/style.xml doc/customize.xml doc/teixsl.html doc/index.xml
	rm -rf release dist
	(cd Test; make clean)
	rm -rf tei-p5-xsl_*
	rm -rf tei-p5-xsl2_*
	-(cd debian-tei-xsl/debian;  rm -rf tei-xsl)
	rm -f teioo.jar
	rm -rf docx/ImageInfo/bin
	rm -f names.xml

tags:
	etags `find . -name "*.xsl" | grep -v "slides/" | grep -v "latex/" | grep -v "html/" | grep -v "fo/" | grep -v "common2/" | grep -v "doc/" `

