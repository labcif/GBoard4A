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


	@serdeIgnore string path;


	/// All keystrokes.
	Info[] inserted;

	/// All deleted sequences.
	Info[] deleted;

	/// All keystrokes pressed and deleted by the order in which they were performed.
	Info[] rawHistory;

	/// All information in RawHistory assembled together for easier readability.
	Info[] rawAssembledHistory;

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
	Info[] relevantHistory;
}
