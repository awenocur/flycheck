EMACS = emacs
EMACSFLAGS =
CASK = cask
VAGRANT = vagrant
SPHINX-BUILD = sphinx-build
INSTALL-INFO = install-info
VERSION := $(shell EMACS=$(EMACS) $(CASK) version)
PKGDIR := $(shell EMACS=$(EMACS) $(CASK) package-directory)

# Export the used EMACS to recipe environments
export EMACS

SRCS = flycheck.el
OBJECTS = $(SRCS:.el=.elc)
PACKAGE_SRCS = $(SRCS) \
	flycheck-pkg.el \
	doc/flycheck.info doc/dir
PACKAGE = flycheck-$(VERSION).tar

.PHONY: compile
compile : $(OBJECTS)

.PHONY: package
package : $(PACKAGE)

$(PACKAGE) : $(PACKAGE_SRCS)
	rm -rf flycheck-$(VERSION)
	mkdir -p flycheck-$(VERSION)
	cp -f $(PACKAGE_SRCS) flycheck-$(VERSION)
	tar cf $(PACKAGE) flycheck-$(VERSION)
	rm -rf flycheck-$(VERSION)

.PHONY: clean-all
clean-all : clean clean-pkgdir clean-doc

.PHONY: clean
clean :
	rm -f $(OBJECTS)
	rm -rf flycheck-*.tar flycheck-pkg.el

.PHONY: packages
packages : $(PKGDIR)

.PHONY: clean-pkgdir
clean-pkgdir :
	rm -rf $(PKGDIR)

.PHONY: test
test : compile
	$(CASK) exec ert-runner

.PHONY: vagrant-test
vagrant-test :
	$(VAGRANT) up
	$(VAGRANT) ssh -c "make -C /flycheck EMACS=$(EMACS) clean test"

.PHONY: doc
doc : info html

.PHONY: html
html :
	$(SPHINX-BUILD) -b html -n -d doc/_build/doctrees doc doc/_build/html

.PHONY: info
info : doc/dir

.PHONY: linkcheck
linkcheck:
	$(SPHINX-BUILD) -b linkcheck -n -d doc/_build/doctrees doc doc/_build/linkcheck

.PHONY: clean-doc
clean-doc:
	rm -rf doc/_build/

%.elc : %.el $(PKGDIR)
	$(CASK) exec $(EMACS) -Q --batch $(EMACSFLAGS) \
		--eval '(setq package-user-dir "$(PKGDIR)")' -f package-initialize \
		-f batch-byte-compile $<

$(PKGDIR) : Cask
	$(CASK) install
	touch $(PKGDIR)

flycheck-pkg.el : Cask
	$(CASK) package

doc/dir : doc/flycheck.info
	$(INSTALL-INFO) doc/flycheck.info doc/dir

doc/flycheck.info : doc/_build/info/flycheck.info
	cp -f $< $@

doc/_build/info/flycheck.texi :
	$(SPHINX-BUILD) -b texinfo -n -d doc/_build/doctrees doc doc/_build/info



