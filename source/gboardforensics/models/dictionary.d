module gboardforensics.models.dictionary;

/**
 * This represents a personal dictionary data structure
 */
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

	/// path to the dictionary
	immutable string path;
	/// list of dictionary entries
	const(Entry)[] entries;
}
