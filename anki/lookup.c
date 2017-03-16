#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>

// https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/DictionaryServicesProgGuide/Introduction/Introduction.html

static char *getCStringFromCFString(CFStringRef s)
{
	if (s == NULL) {
		return NULL;
	}
	CFStringEncoding encoding = kCFStringEncodingUTF8;
	CFIndex length = CFStringGetLength(s);
	CFIndex maxSize = CFStringGetMaximumSizeForEncoding(length, encoding);
	char *buffer = (char *)malloc(maxSize);
	if (CFStringGetCString(s, buffer, maxSize, encoding)) {
		return buffer;
	}
	return NULL;
}

const char *lookup(const char *word)
{
	CFStringRef searchPhrase = CFStringCreateWithCString(NULL, word, kCFStringEncodingUTF8);
	if (searchPhrase) {
		CFRange searchRange = DCSGetTermRangeInString(NULL, searchPhrase, 0);
		if (searchRange.location == kCFNotFound)
			return NULL;
		CFStringRef definition = DCSCopyTextDefinition(NULL, searchPhrase, searchRange);
		CFRelease(searchPhrase);
		if (definition) {
			char *output = getCStringFromCFString(definition);
			CFRelease(definition);
			return output;
		} else {
			return NULL;
		}
	}
	return NULL;
}

void lookup_free(void *p)
{
	free(p);
}
