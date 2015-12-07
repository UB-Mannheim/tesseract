AUTOMAKE_OPTIONS = subdir-objects

if MINGW

gitrev="`git --git-dir=${abs_top_srcdir}/.git --work-tree=${abs_top_srcdir} describe --always --tags`"

all:

winsetup:
	$(MAKE) -C .. install training-install prefix="$(abs_top_builddir)/usr/i686-w64-mingw32"
	makensis -DCROSSBUILD -DSHARED -DSRCDIR=$(top_srcdir) -DVERSION=${gitrev} -NOCD $(top_srcdir)/nsis/tesseract.nsi

endif
