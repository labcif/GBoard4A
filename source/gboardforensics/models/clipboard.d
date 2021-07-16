/**
 * Module representing the serializable model of a Clipboard data source
 *
 * Authors: João Lourenço, Luís Ferreira
 * Copyright: João Lourenço (c) 2021
 *            Luís Ferreira (c) 2021
 * License: GPL-3.0
 */
module gboardforensics.models.clipboard;

import gboardforensics.utils.serialization;
import asdf.serialization;

/**
 * This represents a clipboard data structure
 */
struct Clipboard
{
	/**
	 * This represents a single entry in the dictionary
	 */
	struct Entry
	{
		/**
		 * Entry Type
		 */
		enum Type
		{
			DOCUMENT,
			TEXT,
		}

		/// text
		@serdeIgnoreDefault string text;
		/// HTML text representation
		@serdeIgnoreDefault string html;
		/// type
		Type type;
		/// string representation of the timestamp
		string time;
		/// UNIX epoch formatted timestamp
		size_t timestamp;
		/// URI
		@serdeIgnoreDefault string uri;
		/// Document formatted in base64
		@serdeIgnoreDefault string document;
	}

	/**
	 * Calculates the number of total clipboard entries
	 *
	 * Returns: number of total items
	 */
	@safe pure nothrow
	size_t countItems() const
	{
		return entries.length;
	}

	/// path to the dictionary
	immutable string path;
	/// list of dictionary entries
	SerializableArray!(const(Entry)) entries;
}

///
@safe pure nothrow
unittest
{
	Clipboard c;
	c.entries = new Clipboard.Entry[10];

	assert(c.countItems == 10);
}
