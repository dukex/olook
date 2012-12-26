#include <ruby.h>
#include <time.h>
#include <stdio.h>

static const size_t buf_capa = sizeof("Thu, 01 Jan 1970 00:00:00 GMT");
static VALUE buf;
static char *buf_ptr;
static const char *const week[] = {
	"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
};
static const char *const months[] = {
	"Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};

/* for people on wonky systems only */
#ifndef HAVE_GMTIME_R
static struct tm * my_gmtime_r(time_t *now, struct tm *tm)
{
	struct tm *global = gmtime(now);
	if (global)
		*tm = *global;
	return tm;
}
#  define gmtime_r my_gmtime_r
#endif


/*
 * Returns a string which represents the time as rfc1123-date of HTTP-date
 * defined by RFC 2616:
 *
 *   day-of-week, DD month-name CCYY hh:mm:ss GMT
 *
 * Note that the result is always GMT.
 *
 * This method is identical to Time#httpdate in the Ruby standard library,
 * except it is implemented in C for performance.  We always saw
 * Time#httpdate at or near the top of the profiler output so we
 * decided to rewrite this in C.
 *
 * Caveats: it relies on a Ruby implementation with the global VM lock,
 * a thread-safe version will be provided when a Unix-only, GVL-free Ruby
 * implementation becomes viable.
 */
static VALUE httpdate(VALUE self)
{
	static time_t last;
	time_t now = time(NULL); /* not a syscall on modern 64-bit systems */
	struct tm tm;

	if (last == now)
		return buf;
	last = now;
	gmtime_r(&now, &tm);

	/* we can make this thread-safe later if our Ruby loses the GVL */
	snprintf(buf_ptr, buf_capa,
	         "%s, %02d %s %4d %02d:%02d:%02d GMT",
	         week[tm.tm_wday],
	         tm.tm_mday,
	         months[tm.tm_mon],
	         tm.tm_year + 1900,
	         tm.tm_hour,
	         tm.tm_min,
	         tm.tm_sec);

	return buf;
}

void init_unicorn_httpdate(void)
{
	VALUE mod = rb_const_get(rb_cObject, rb_intern("Unicorn"));
	mod = rb_define_module_under(mod, "HttpResponse");

	buf = rb_str_new(0, buf_capa - 1);
	rb_global_variable(&buf);
	buf_ptr = RSTRING_PTR(buf);
	httpdate(Qnil);

	rb_define_method(mod, "httpdate", httpdate, 0);
}
