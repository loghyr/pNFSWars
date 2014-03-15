# Copyright (C) The IETF Trust (2014)
#

YEAR=`date +%Y`
MONTH=`date +%B`
DAY=`date +%d`
PREVVERS=01
VERS=02
BASEDOC=draft-haynes-nfsv4-layout-types
XML2RFC=xml2rfc

autogen/%.xml : %.x
	@mkdir -p autogen
	@rm -f $@.tmp $@
	@cat $@.tmp | sed 's/^\%//' | sed 's/</\&lt;/g'| \
	awk ' \
		BEGIN	{ print "<figure>"; print" <artwork>"; } \
			{ print $0 ; } \
		END	{ print " </artwork>"; print"</figure>" ; } ' \
	| expand > $@
	@rm -f $@.tmp

all: html txt

#
# Build the stuff needed to ensure integrity of document.
common: testx html

txt: $(BASEDOC)-$(VERS).txt

html: $(BASEDOC)-$(VERS).html

nr: $(BASEDOC)-$(VERS).nr

xml: $(BASEDOC)-$(VERS).xml

clobber:
	$(RM) $(BASEDOC)-$(VERS).txt \
		$(BASEDOC)-$(VERS).html \
		$(BASEDOC)-$(VERS).nr
	export SPECVERS := $(VERS)
	export VERS := $(VERS)

clean:
	rm -f $(AUTOGEN)
	rm -rf autogen
	rm -f $(BASEDOC)-$(VERS).xml
	rm -rf draft-$(VERS)
	rm -f draft-$(VERS).tar.gz
	rm -rf testx.d
	rm -rf draft-tmp.xml

# Parallel All
pall: 
	$(MAKE) xml
	( $(MAKE) txt ; echo .txt done ) & \
	( $(MAKE) html ; echo .html done ) & \
	wait

$(BASEDOC)-$(VERS).txt: $(BASEDOC)-$(VERS).xml
	${XML2RFC} --text  $(BASEDOC)-$(VERS).xml -o $@

$(BASEDOC)-$(VERS).html: $(BASEDOC)-$(VERS).xml
	${XML2RFC}  --html $(BASEDOC)-$(VERS).xml -o $@

$(BASEDOC)-$(VERS).nr: $(BASEDOC)-$(VERS).xml
	${XML2RFC} --nroff $(BASEDOC)-$(VERS).xml -o $@

pnfswars_front_autogen.xml: pnfswars_front.xml Makefile
	sed -e s/DAYVAR/${DAY}/g -e s/MONTHVAR/${MONTH}/g -e s/YEARVAR/${YEAR}/g < pnfswars_front.xml > pnfswars_front_autogen.xml

pnfswars_rfc_start_autogen.xml: pnfswars_rfc_start.xml Makefile
	sed -e s/VERSIONVAR/${VERS}/g < pnfswars_rfc_start.xml > pnfswars_rfc_start_autogen.xml

AUTOGEN =	\
		pnfswars_front_autogen.xml \
		pnfswars_rfc_start_autogen.xml

START_PREGEN = pnfswars_rfc_start.xml
START=	pnfswars_rfc_start_autogen.xml
END=	pnfswars_rfc_end.xml

FRONT_PREGEN = pnfswars_front.xml

IDXMLSRC_BASE = \
	pnfswars_middle_start.xml \
	pnfswars_middle_introduction.xml \
	pnfswars_middle_control.xml \
	pnfswars_middle_existing.xml \
	pnfswars_middle_wrapup.xml \
	pnfswars_middle_security.xml \
	pnfswars_middle_iana.xml \
	pnfswars_middle_end.xml \
	pnfswars_back_front.xml \
	pnfswars_back_references.xml \
	pnfswars_back_acks.xml \
	pnfswars_back_back.xml

IDCONTENTS = pnfswars_front_autogen.xml $(IDXMLSRC_BASE)

IDXMLSRC = pnfswars_front.xml $(IDXMLSRC_BASE)

draft-tmp.xml: $(START) Makefile $(END) $(IDCONTENTS)
		rm -f $@ $@.tmp
		cp $(START) $@.tmp
		chmod +w $@.tmp
		for i in $(IDCONTENTS) ; do cat $$i >> $@.tmp ; done
		cat $(END) >> $@.tmp
		mv $@.tmp $@

$(BASEDOC)-$(VERS).xml: draft-tmp.xml $(IDCONTENTS) $(AUTOGEN)
		rm -f $@
		cp draft-tmp.xml $@

genhtml: Makefile gendraft html txt draft-$(VERS).tar
	./gendraft draft-$(PREVVERS) \
		$(BASEDOC)-$(PREVVERS).txt \
		draft-$(VERS) \
		$(BASEDOC)-$(VERS).txt \
		$(BASEDOC)-$(VERS).html \
		$(BASEDOC)-dot-x-04.txt \
		$(BASEDOC)-dot-x-05.txt \
		draft-$(VERS).tar.gz

testx: 
	rm -rf testx.d
	mkdir testx.d
	( cd testx.d ; \
		rpcgen -a labelednfs.x ; \
		$(MAKE) -f make* )

spellcheck: $(IDXMLSRC)
	for f in $(IDXMLSRC); do echo "Spell Check of $$f"; spell +dictionary.txt $$f; done

AUXFILES = \
	dictionary.txt \
	gendraft \
	Makefile \
	errortbl \
	rfcdiff \
	xml2rfc_wrapper.sh \
	xml2rfc

DRAFTFILES = \
	$(BASEDOC)-$(VERS).txt \
	$(BASEDOC)-$(VERS).html \
	$(BASEDOC)-$(VERS).xml

draft-$(VERS).tar: $(IDCONTENTS) $(START_PREGEN) $(FRONT_PREGEN) $(AUXFILES) $(DRAFTFILES)
	rm -f draft-$(VERS).tar.gz
	tar -cvf draft-$(VERS).tar \
		$(START_PREGEN) \
		$(END) \
		$(FRONT_PREGEN) \
		$(IDCONTENTS) \
		$(AUXFILES) \
		$(DRAFTFILES) \
		gzip draft-$(VERS).tar
