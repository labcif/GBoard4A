module gboardforensics.models.translatecache;

import gboardforensics.utils.serialization;

import std.typecons : Nullable;

import asdf.serialization : serdeIgnore, serdeIgnoreDefault;

struct TranslateCache
{
	struct Data {
		size_t timestamp;
		string time;
		string orig;
		string trans;
		string from;
		string to;
		string requestURL;
		string rawRequest;
		string rawResponse;
		string requestPath;
		string responsePath;
	}

	@safe pure nothrow
	size_t countItems() const
	{
		return data.length;
	}

	SerializableArray!(const(Data)) data;
}
