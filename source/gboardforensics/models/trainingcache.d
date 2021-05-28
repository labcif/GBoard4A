module gboardforensics.models.trainingcache;

import std.typecons : Nullable;

import mir.serde : serdeIgnore, serdeIgnoreDefault;

struct TrainingCache
{
	struct Info
	{
		string time;
		string sequence;
		@serdeIgnoreDefault Nullable!bool deleted;
		size_t timestamp;
	}

	@safe pure nothrow
	size_t countItems() const
	{
		return inserted.length +
			deleted.length +
			historyTimeline.length +
			assembledTimeline.length +
			processedHistory.length;
	}

	/// File path
	immutable string path;

	/// All keystrokes.
	const(Info)[] inserted;

	/// All deleted sequences.
	const(Info)[] deleted;

	/// All keystrokes pressed and deleted by the order in which they were performed.
	const(Info)[] historyTimeline;

	/// All information in HistoryTimeline assembled together for easier readability.
	const(Info)[] assembledTimeline;

	/**
	Contains similar information to History but with some sequences removed. The
	selection is done by mathing a sequence from all the keystrokes and it's
	timestamp to a the same in the deleted sequences table. However this is not
	a 100% viable solution as it can remove the wrong sequences and it still
	leaves out others that should be removed.

	Examples:
	---
	* lets say a user has written 'gostoe' and deleted the character 'o'. GBoard
	  might store all these keystrokes with the same timestamp. Which means the
	  final sequence using this method might be the output 'gste'.

	* now lets say the has written 'helllo' deleted 'l' and then 'world'. GBoard
	  might store the deleted sequence with the wrong timestamp mathing all
	  timestamps in the sequence 'world'. Which means the final sequence using
	  this method might be the output 'helllo word'.
	---
	*/
	const(Info)[] processedHistory;
}

///
@safe pure nothrow
unittest
{
	TrainingCache tc;
	tc.inserted = new TrainingCache.Info[10];
	tc.deleted = new TrainingCache.Info[5];
	tc.historyTimeline = new TrainingCache.Info[7];
	tc.assembledTimeline = new TrainingCache.Info[8];
	tc.processedHistory = new TrainingCache.Info[1];

	assert(tc.countItems == 31);
}
