/* t3_icu.c — does our cross-built ICU actually produce correct output?
 *
 * A clean link proves nothing about ICU: the whole risk in a 338K-line C++
 * cross-build with 20 MB of vendored data is that it links and then formats
 * dates wrongly, or silently finds no locale data and falls back to root.
 * Every check below therefore prints a VALUE, not a status.
 *
 * Everything is pinned — locale, timezone, a fixed UTC instant — so the output
 * is byte-comparable between our Mach-O build under machorun and a native
 * build of the SAME swift-foundation-icu source on macOS. The oracle is a
 * reference build of identical source, not Apple's shipped libicucore, whose
 * ICU version differs.
 *
 * The data check is the load-bearing one: if the vendored
 * icu_packaged_main_data blobs are not wired up, u_init still succeeds and
 * formatting silently degrades to root-locale output. `de_DE` month names are
 * the cheapest way to prove real locale data is present.
 */
#include <_foundation_unicode/utypes.h>
#include <_foundation_unicode/uloc.h>
#include <_foundation_unicode/ucal.h>
#include <_foundation_unicode/udat.h>
#include <_foundation_unicode/unum.h>
#include <_foundation_unicode/ucol.h>
#include <_foundation_unicode/ustring.h>
#include <_foundation_unicode/uversion.h>
#include <stdio.h>
#include <string.h>

static void putustr(const char *key, const UChar *s, int32_t len) {
    char buf[512];
    UErrorCode e = U_ZERO_ERROR;
    int32_t n = 0;
    u_strToUTF8(buf, sizeof buf, &n, s, len, &e);
    if (U_FAILURE(e)) { printf("%s=<err %s>\n", key, u_errorName(e)); return; }
    buf[n < (int32_t)sizeof buf ? n : (int32_t)sizeof buf - 1] = '\0';
    printf("%s=%s\n", key, buf);
}

int main(void) {
    UErrorCode e = U_ZERO_ERROR;

    /* 1. Version — establishes WHICH ICU both sides are running. */
    UVersionInfo v;
    u_getVersion(v);
    printf("icu.version=%d.%d\n", v[0], v[1]);

    /* 2. Locale handling. */
    char lang[16];
    e = U_ZERO_ERROR;
    uloc_getLanguage("de_DE@collation=phonebook", lang, sizeof lang, &e);
    printf("uloc.lang=%s\n", lang);

    UChar dbuf[128];
    e = U_ZERO_ERROR;
    uloc_getDisplayLanguage("de", "en", dbuf, 128, &e);
    putustr("uloc.display_de_in_en", dbuf, -1);

    /* 3. Calendar: a fixed UTC instant, decomposed. 1234567890000 ms is
       2009-02-13T23:31:30Z. Any timezone-database or arithmetic error moves
       one of these fields. */
    static const UChar utc[] = { 'U','T','C',0 };
    e = U_ZERO_ERROR;
    UCalendar *cal = ucal_open(utc, -1, "en_US", UCAL_GREGORIAN, &e);
    if (U_FAILURE(e)) { printf("ucal.open=<err %s>\n", u_errorName(e)); return 1; }
    ucal_setMillis(cal, 1234567890000.0, &e);
    printf("ucal.year=%d\n",   ucal_get(cal, UCAL_YEAR, &e));
    printf("ucal.month=%d\n",  ucal_get(cal, UCAL_MONTH, &e));   /* 0-based */
    printf("ucal.day=%d\n",    ucal_get(cal, UCAL_DATE, &e));
    printf("ucal.hour=%d\n",   ucal_get(cal, UCAL_HOUR_OF_DAY, &e));
    printf("ucal.minute=%d\n", ucal_get(cal, UCAL_MINUTE, &e));
    printf("ucal.dow=%d\n",    ucal_get(cal, UCAL_DAY_OF_WEEK, &e));

    /* 4. Date formatting in TWO locales. The German one is the real data
          check: root-locale fallback would print English month names. */
    e = U_ZERO_ERROR;
    UDateFormat *df = udat_open(UDAT_MEDIUM, UDAT_MEDIUM, "en_US", utc, -1, NULL, 0, &e);
    UChar out[256];
    udat_format(df, 1234567890000.0, out, 256, NULL, &e);
    putustr("udat.en_US", out, -1);
    udat_close(df);

    /* NOTE THE ARGUMENT ORDER: udat_open takes timeStyle FIRST, then dateStyle.
       Passing (UDAT_LONG, UDAT_NONE) yields a long TIME and no date, which is
       still deterministic and so still diffs clean — it just silently stops
       testing month names, which is the whole point of this case. */
    e = U_ZERO_ERROR;
    df = udat_open(UDAT_NONE, UDAT_LONG, "de_DE", utc, -1, NULL, 0, &e);
    udat_format(df, 1234567890000.0, out, 256, NULL, &e);
    putustr("udat.de_DE_longdate", out, -1);
    udat_close(df);

    /* 5. Number formatting: grouping separators and decimal marks differ by
          locale, so this catches a root-locale fallback too. */
    e = U_ZERO_ERROR;
    UNumberFormat *nf = unum_open(UNUM_DECIMAL, NULL, 0, "en_US", NULL, &e);
    unum_formatDouble(nf, 1234567.891, out, 256, NULL, &e);
    putustr("unum.en_US", out, -1);
    unum_close(nf);

    e = U_ZERO_ERROR;
    nf = unum_open(UNUM_DECIMAL, NULL, 0, "de_DE", NULL, &e);
    unum_formatDouble(nf, 1234567.891, out, 256, NULL, &e);
    putustr("unum.de_DE", out, -1);
    unum_close(nf);

    e = U_ZERO_ERROR;
    nf = unum_open(UNUM_CURRENCY, NULL, 0, "en_US", NULL, &e);
    unum_formatDouble(nf, 42.5, out, 256, NULL, &e);
    putustr("unum.currency_en_US", out, -1);
    unum_close(nf);

    /* 6. Collation. German phonebook ordering differs from default, which
          only works if tailoring data loaded. */
    e = U_ZERO_ERROR;
    UCollator *co = ucol_open("de_DE", &e);
    static const UChar a[] = { 0x00E4, 0 };   /* a-umlaut */
    static const UChar b[] = { 'z', 0 };
    printf("ucol.de_ae_before_z=%d\n", ucol_strcoll(co, a, -1, b, -1) < 0);
    ucol_close(co);

    /* 7. Case mapping with a locale-specific rule: Turkish dotless i. */
    e = U_ZERO_ERROR;
    static const UChar I[] = { 'I', 0 };
    u_strToLower(out, 256, I, -1, "tr_TR", &e);
    putustr("ustr.tr_lower_I", out, -1);

    ucal_close(cal);
    return 0;
}
