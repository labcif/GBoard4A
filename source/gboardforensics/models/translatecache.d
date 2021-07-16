/**
 * Module representing the serializable model of the Translation Cache data
 * source.
 *
 * Authors: João Lourenço, Luís Ferreira
 * Copyright: João Lourenço (c) 2021
 *            Luís Ferreira (c) 2021
 * License: GPL-3.0
 */
module gboardforensics.models.translatecache;

import gboardforensics.utils.serialization;

import std.typecons : Nullable;

import asdf.serialization : serdeIgnore, serdeIgnoreDefault;

/**
 * Serializable model of the Translation Cache data source
 */
struct TranslateCache
{
	/**
	 * Entry representing each pair of request and response
	 */
	struct Data {
		size_t timestamp; /// Timestamp in UNIX epoch (milliseconds)
		string time; /// Text representation of the timestamp field
		string orig; /// Original text to be translated
		string trans; /// Translated text
		string from; /// Source language
		string to; /// Target language
		string requestURL; /// Request URL to Google internal API
		string rawRequest; /// Raw request data encoded in base64
		string rawResponse; /// Raw response data encoded in base64
		string requestPath; /// Path where the request is stored
		string responsePath; /// Path where the response is stored
	}

	/**
	 * Count number of entries fetched
	 *
	 * Returns: number of entries
	 */
	@safe pure nothrow
	size_t countItems() const
	{
		return data.length;
	}

	/// Serializable array of entries
	SerializableArray!(const(Data)) data;
}
