module gboardforensics.models.dictionary;

import gboardforensics.utils.serialization;

/**
 * This represents a personal dictionary data structure
 */
@safe pure nothrow
struct Dictionary
{
	/**
	 * This represents a single entry in the dictionary
	 */
	struct Entry
	{
		/// word to be shortcuted
		string word;
		/// word shortcut
		string shortcut;
		/// locale of the keyboard
		string locale;
	}

	/**
	 * Calculates the number of total dictionary entries
	 *
	 * Returns: number of total items
	 */
	@safe pure nothrow
	size_t countItems() const
	{
		return entries.length;
	}

	@safe pure nothrow @nogc
	this(string path, const(Entry)[] entries)
	{
		this.path = path;
		this.entries = entries;
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
	Dictionary dict = Dictionary("foo", [
		Dictionary.Entry("foo", "f", "en-US"),
		Dictionary.Entry("bar", "b", "en-US")
	]);

	assert(dict.countItems() == 2);
}
