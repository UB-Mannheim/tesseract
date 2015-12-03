AUTOMAKE_OPTIONS = subdir-objects

if MINGW

gitrev="`git --git-dir=${abs_top_srcdir}/.git --work-tree=${abs_top_srcdir} describe --always --tags`"

all winsetup:
	makensis -DCROSSBUILD -DSHARED -DSRCDIR=$(top_srcdir) -DVERSION=${gitrev} -NOCD $(top_srcdir)/nsis/tesseract.nsi

endif
