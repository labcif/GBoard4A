module gboardforensics.gatherers.translatecache;

import gboardforensics.gatherers : IGatherer;
import gboardforensics.models : TranslateCache;

import std.algorithm : filter, findSplitAfter, findSplitBefore, fold, map, sort, splitter;
import std.file : dirEntries, DirEntry, read, readText, SpanMode;
import std.path : baseName, buildPath, extension, stripExtension;
import std.range : assocArray, back, front, split, tail;
import std.regex : matchFirst, regex;
import std.typecons : No, tuple;

class TranslateCacheGatherer : IGatherer
{
	this(DirEntry _dir)
		in (_dir.isDir())
	{
		this._dir = _dir;
	}

	void gather()
	{
		import std.array : array;

		_cache.data = _dir.name
			.dirEntries(SpanMode.shallow)
			.filter!"a.isFile"
			.filter!(n => n.baseName.matchFirst(regex(r".+\.[0|1]$")))
			.fold!((aa, path) {
				immutable name = path.stripExtension.baseName();
				immutable exts = path.extension();

				final switch (exts)
				{
					case ".0": aa.require(name).request = path; return aa;
					case ".1": aa.require(name).response = path; return aa;
				}
			})((TranslateCacheFiles[string]).init)
			.byValue
			.map!toData
			.array;
	}


	@property const(TranslateCache) translateCache() const
	{
		return _cache;
	}


private:
	static TranslateCache.Data toData(TranslateCacheFiles tcf)
	{
		import std.ascii : newline;
		import std.base64 : Base64;
		import std.conv : to;
		import std.datetime : DateTime, SysTime, UTC;
		import std.format : format, formattedRead;
		import std.json : parseJSON;
		import std.string : startsWith;
		import std.zlib : UnCompress;

		import vibe.textfilter.urlencode : urlDecode;
		import vibe.inet.url : URL;

		string request = tcf.request.readText();
		auto lines = request.splitter(newline);

		// get the response base on the enconding
		// defaults to plain text
		string response;
		switch (lines
			.filter!(s => s.startsWith("Content-Encoding:"))
			.front // extract the string from the range
			.split // split by white characters
			.back // get the last value
		) {
			case "gzip": response = cast(string)(new UnCompress().uncompress(tcf.response.read())); break;
			default: response = tcf.response.readText();
		}

		auto query = lines.front.to!URL // convert to URL
			.queryString // get the query part
			.splitter('&') // split each by '&'
			.map!(s => s.split("=")) // map each to decoded split by '='
			.map!(a => tuple(a.front.urlDecode, a.back.urlDecode)) // map to tuple
			.assocArray; // map to Associative Array

		// can't have multiple sentences, so we can just grab the first element
		auto json = parseJSON(response)["sentences"].array.front;

		TranslateCache.Data data;
		data.requestPath = tcf.request;
		data.responsePath = tcf.response;
		data.rawRequest = Base64.encode(cast(ubyte[]) request).to!string;
		data.rawResponse = Base64.encode(cast(ubyte[]) response).to!string;
		data.from = query["sl"];
		data.to = query["tl"];
		data.orig = json["orig"].str;
		data.trans = json["trans"].str;
		data.requestURL = lines.front;

		data.time = lines
			.filter!(s => s.startsWith("Date:"))
			.front
			.findSplitAfter(", ")[1]
			.findSplitBefore(" GMT")[0];

		string day, month, year, hours;
		data.time.idup.formattedRead!"%s %s %s %s"(day, month, year, hours);
		data.timestamp = SysTime(
				DateTime.fromSimpleString(format!"%s-%s-%s %s"(year, month, day, hours)),
				UTC()
			).toUnixTime();

		return data;
	}

	struct TranslateCacheFiles {
		string request;
		string response;
	}

	DirEntry _dir;
	TranslateCache _cache;
}
