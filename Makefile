
VERSION := $(shell date +%y.%m-%d%H%M%S)

PLAYER_JS := $(wildcard player/js/*.js)
EXTRAS_JS := $(wildcard player/extras/*.js)

#MINIFY_OPT += --nomunge

JUICER_OPT += --force
JUICER_OPT += --skip-verification
 JUICER_OPT += --minifyer none

MINIFY := juicer merge $(JUICER_OPT) --arguments "$(MINIFY_OPT)"

AUTOLINT := ./node_modules/autolint/bin/autolint

MSGFMT := /usr/lib/python2.7/Tools/i18n/msgfmt.py

EDITOR_SRC := \
	$(wildcard editors/inkscape/*.py) \
	$(wildcard editors/inkscape/*.inx) \
	$(wildcard editors/inkscape/sozi/*.*)

EDITOR_PO := $(wildcard editors/inkscape/sozi/lang/*.po)

GETTEXT_SRC := \
	$(wildcard editors/inkscape/*.py) \
	$(wildcard editors/inkscape/sozi/*.py)

PLAYER_SRC := \
	$(wildcard player/js/extras/*.js) \
	player/js/sozi.js \
	player/css/sozi.css

DOC := \
	$(wildcard doc/install*.html) \
	$(wildcard doc/*license.txt)

TARGET := \
    $(subst editors/inkscape,release,$(EDITOR_SRC)) \
    $(patsubst editors/inkscape/sozi/lang/%.po,release/sozi/lang/%/LC_MESSAGES/sozi.mo,$(EDITOR_PO)) \
    $(addprefix release/sozi/,$(notdir $(PLAYER_SRC) $(DOC)))

INSTALL_DIR := $(HOME)/.config/inkscape/extensions

TIMESTAMP := release/sozi-timestamp-$(VERSION)

.PHONY: zip verify minify install doc timestamp clean

all: zip

zip: release/sozi-release-$(VERSION).zip

verify: $(PLAYER_JS) $(EXTRAS_JS)
	$(AUTOLINT) --once

minify: release/sozi.js release/sozi.css

install: $(TARGET)
	cp -r release/sozi* $(INSTALL_DIR)

timestamp: release/sozi-timestamp-$(VERSION)

doc: $(PLAYER_JS) $(EXTRAS_JS)
	jsdoc --directory=web/api --recurse=1 \
		--allfunctions --private \
		--template=jsdoc-templates \
		player/js

pot: $(GETTEXT_SRC)
	xgettext --package-name=Sozi --package-version=$(VERSION) --output=editors/inkscape/sozi/lang/sozi.pot $^

$(TIMESTAMP):
	mkdir -p release ; touch $@

release/sozi-release-$(VERSION).zip: $(TARGET)
	cd release ; zip $(notdir $@) $(notdir $^)

release/sozi/sozi.js: $(PLAYER_JS)
	$(MINIFY) --output $@ player/js/sozi.js

release/sozi/%.css: player/css/%.css
	$(MINIFY) --output $@ $<

release/sozi/%.js: player/js/extras/%.js
	$(MINIFY) --output $@ $<

release/sozi/lang/%/LC_MESSAGES/sozi.mo: editors/inkscape/sozi/lang/%.po
	mkdir -p $(dir $@) ; $(MSGFMT) -o $@ $<

release/sozi/version.py: editors/inkscape/sozi/version.py $(TIMESTAMP)
	mkdir -p release/sozi ; sed "s/{{SOZI_VERSION}}/$(VERSION)/g" $< > $@

release/%: editors/inkscape/%
	cp $< $@

release/sozi/%: editors/inkscape/sozi/%
	mkdir -p release/sozi ; cp $< $@

release/sozi/%: doc/%
	mkdir -p release/sozi ; cp $< $@

clean:
	rm -f $(TARGET) release/sozi-timestamp-*

