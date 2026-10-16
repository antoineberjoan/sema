// Build tool: Finder's backgroundImageAlias still uses an Alias Manager record.
// This helper is not bundled with Sema and never operates the Finder UI.
#include <CoreServices/CoreServices.h>
#include <stdio.h>

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage : finder-alias fond-monté destination\n");
        return 1;
    }
    FSRef target;
    OSStatus status = FSPathMakeRef((const UInt8 *)argv[1], &target, NULL);
    AliasHandle alias = NULL;
    if (status == noErr) status = FSNewAliasMinimal(&target, &alias);
    if (status != noErr || alias == NULL) {
        fprintf(stderr, "Alias du fond DMG impossible (%d).\n", (int)status);
        return 1;
    }
    FILE *output = fopen(argv[2], "wb");
    if (output == NULL) { DisposeHandle((Handle)alias); return 1; }
    Size size = GetHandleSize((Handle)alias);
    size_t written = fwrite(*alias, 1, (size_t)size, output);
    int close_status = fclose(output);
    DisposeHandle((Handle)alias);
    return written == (size_t)size && close_status == 0 ? 0 : 1;
}
