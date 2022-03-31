AUTOMAKE_OPTIONS = foreign
SUBDIRS = src \
	  src/HL \
	  scripts \
	  scripts/HLscripts \
	  scripts/MOPAC_DEV \
	  docs \
	  modules \
	  examples \
	  share 

EXTRA_DIST = license.txt \
	     install-gnu-parallel-from-epel.sh \
	     install-gnu-parallel-from-source.sh \
	     install-required-packages-centos7.sh \
	     install-required-packages-ubuntu-16.4lts.sh \
	     install-required-packages-sl7.sh README.md logo.png

dist-hook:
	rm -rf `find $(distdir) -name .svn`



