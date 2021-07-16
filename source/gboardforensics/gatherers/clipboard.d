/**
 * This module represents the gatherer logic for the clipboard manager
 *
 * Authors: João Lourenço, Luís Ferreira
 * Copyright: João Lourenço (c) 2021
 *            Luís Ferreira (c) 2021
 * License: GPL-3.0
 */
module gboardforensics.gatherers.clipboard;

import gboardforensics.gatherers;
import gboardforensics.models.clipboard;

import std.algorithm;
import std.file;
import std.array;
import std.path;
import std.file;
import std.base64;
import std.string : stripLeft;
import std.range : back;

import d2sqlite3;

/**
 * This represents a gatherer for GBoard clipboard
 */
class ClipboardGatherer : IGatherer
{
	/**
	 * Constructs a gatherer with a given path
	 *
	 * Params:
	 *   path = path to the clipboard file
	 */
	this(string path)
		in(exists(path))
		in(isFile(path))
	{
		_clipboard.path = path;
	}

	///
	void gather()
	{
		auto db = Database(_clipboard.path);
		scope(exit) db.close();

		Appender!(Clipboard.Entry[]) entries;

		db.execute(`SELECT
				text,
				html_text AS html,
				uri IS NULL OR uri = "" AS type,
				datetime(timestamp/1000, 'unixepoch') AS time,
				timestamp,
				uri,
				"" AS content
			FROM clips`)
			.map!(r => r.as!(Clipboard.Entry))
			.each!((Clipboard.Entry e) {
				if(e.type == Clipboard.Entry.Type.DOCUMENT)
				{
					auto documentPath = _clipboard.path
						.dirName
						.buildPath("..",
							"files", e.uri
							.findSplitAfter("content://")[1]
							.findSplitAfter("/")[1]
					);

					if(documentPath.exists && documentPath.isFile)
						e.document = Base64.encode(cast(ubyte[])documentPath.read);
				}
				entries ~= e;
			});

		_clipboard.entries = entries[];
	}

	/**
	 * Gets the collected clipboard
	 *
	 * Returns: clipboard data serializable structure
	 */
	@property const(Clipboard) clipboard() const
	{
		return _clipboard;
	}

	private Clipboard _clipboard;
}
