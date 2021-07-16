/**
 * This module represents the gatherer logic for the personal dictionary
 *
 * Authors: João Lourenço, Luís Ferreira
 * Copyright: João Lourenço (c) 2021
 *            Luís Ferreira (c) 2021
 * License: GPL-3.0
 */
module gboardforensics.gatherers.dictionary;

import gboardforensics.gatherers;
import gboardforensics.models.dictionary;

import std.algorithm;
import std.file;
import std.array;

import d2sqlite3;

/**
 * This represents a gatherer for GBoard personal dictionaries
 */
final class DictionaryGatherer : IGatherer
{
	/**
	 * Constructs a gatherer with a given path
	 *
	 * Params:
	 *   path = path to the dictionary file
	 */
	this(string path)
		in(exists(path))
		in(isFile(path))
	{
		_dictionary.path = path;
	}

	///
	void gather()
	{
		auto db = Database(_dictionary.path);
		scope(exit) db.close();

		_dictionary.entries = db.execute("SELECT word, shortcut, locale FROM entry")
			.map!(r => r.as!(Dictionary.Entry))
			.array;
	}

	/**
	 * Gets the collected dictionary
	 *
	 * Returns: dictionary data structure
	 */
	@property const(Dictionary) dictionary() const
	{
		return _dictionary;
	}

	private Dictionary _dictionary;
}
