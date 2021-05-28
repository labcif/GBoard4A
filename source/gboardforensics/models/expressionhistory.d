module gboardforensics.models.expressionhistory;

import asdf.serialization;
import gboardforensics.utils.serialization;

/**
 * This represents an expression history structure
 */
struct ExpressionHistory
{
	/**
	 * This represents a single entry in the emoji table
	 */
	struct Emoji
	{
		/// Emoji text representation
		@serdeIgnoreDefault string emoji;
		/// Base emoji text representation
		@serdeIgnoreDefault string baseEmoji;
		/// string representation of the last timestamp
		string lastTime;

		/**
		 * Last UNIX epoch formatted timestamp representing last time the emoji
		 * was used.
		 */
		size_t lastTimestamp;

		/// Number of times the emoji was shared
		@serdeIgnoreDefault int shares;
	}

	struct Emoticon
	{
		/// Emoticon text representation
		@serdeIgnoreDefault string emoticon;
		/// string representation of the last timestamp
		string lastTime;

		/**
		 * Last UNIX epoch formatted timestamp representing last time the
		 * emoticon was used.
		 */
		size_t lastTimestamp;

		/// Number of times the emoji was shared
		@serdeIgnoreDefault int shares;
	}

	/**
	 * Calculates the number of total emojis and emoticons
	 *
	 * Returns: number of total items
	 */
	@safe pure nothrow
	size_t countItems() const
	{
		return emojis.length + emoticons.length;
	}

	/// path to the expression history
	immutable string path;
	/// list of emojis
	SerializableArray!(const(Emoji)) emojis;
	/// list of emoticons
	SerializableArray!(const(Emoticon)) emoticons;
}

///
@safe pure nothrow
unittest
{
	ExpressionHistory eh;
	eh.emojis = new ExpressionHistory.Emoji[10];
	eh.emoticons = new ExpressionHistory.Emoticon[5];

	assert(eh.countItems == 15);
}
