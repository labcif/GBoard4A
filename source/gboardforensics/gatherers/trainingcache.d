module gboardforensics.gatherers.trainingcache;

import gboardforensics.gatherers;
import gboardforensics.models.trainingcache;
import gboardforensics.analysis : DBVERSION;

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.format;
import std.path;
import std.range : ElementType;

import core.thread;

import d2sqlite3;

class TrainingCacheGatherer : IGatherer
{
	this(string path, DBVERSION dbversion)
		in (path.exists())
		in (path.isFile())
	{
		_trainingcache.path = path;
		_dbversion = dbversion;
	}

	void gather()
	{
		Database db = Database(_trainingcache.path);
		scope(exit) db.close();

		switch (_dbversion)
		{
			case DBVERSION.Trainingcache2: prepTrainingCache2(db); break;
			default:
		}
	}

	/**
	Both 'trainingcache2.db' and 'trainingcache3.db' databases have almost
	the same table structure. The only difference being the table
	'training_input_events_table' which if it doesn't exists it is split in
	two other tables 's_table' and 'tf_table'. The 's_table', according to
	[this blog](http://www.swiftforensics.com/2021/01/gboard-has-some-interesting-data.html),
	stores the information about the focused application and the 'tf_table'
	contains information about all keystrokes. On the other hand
	'training_input_events_table' has all this information in one place, however
	keystrokes are not stored in plain text as it is in 'tf_table' but only in
	the protobuf field.
	*/
	private void prepTrainingCache2(Database db)
	{

		// checks if the database contains the 'training_input_events_table'
		immutable hasTIET = !db.execute("
			SELECT name
			FROM sqlite_master
			WHERE LOWER(type) IN ('table','view')
			AND LOWER(name) = 'training_input_events_table'"
		).empty;

		if (!hasTIET)
		{
			// inserted sequences
			_trainingcache.inserted = db.execute("
				SELECT datetime(_timestamp/1000, 'unixepoch') as time, f3 as sequence, _timestamp FROM tf_table
			").map!((r) {
				TrainingCache.Info info;
				info.time = r["time"].as!string;
				info.sequence = r["sequence"].as!string;
				info.timestamp = r["_timestamp"].as!size_t;
				return info;
			}).array;

			// deleted sequences
			_trainingcache.deleted = db.execute("
				SELECT datetime(_timestamp/1000, 'unixepoch') as time, f5 as sequence, _timestamp FROM d_table
			").map!((r) {
				TrainingCache.Info info;
				info.time = r["time"].as!string;
				info.sequence = r["sequence"].as!string;
				info.timestamp = r["_timestamp"].as!size_t;
				return info;
			}).array;

			static immutable historyQuery = r"
				SELECT * FROM (
					SELECT datetime(_timestamp/1000, 'unixepoch') as time, f2, f3 as sequence, false as deleted, _timestamp
					FROM tf_table
					UNION
					SELECT datetime(_timestamp/1000, 'unixepoch') as time, f2, f5 as sequence, true as deleted, _timestamp
					FROM d_table
				)
				ORDER BY 1, 2";

			// raw history
			_trainingcache.rawHistory = db.execute(format!"
				SELECT time, sequence, deleted, _timestamp FROM (%s)"(historyQuery))
			.map!(r => r.as!(TrainingCache.Info)).array;

			// assembled raw history
			_trainingcache.rawAssembledHistory = db.execute(format!"
				SELECT time, group_concat(sequence, '') as sequence, deleted, _timestamp
				FROM (%s) GROUP BY time, deleted"(historyQuery))
			.map!(r => r.as!(TrainingCache.Info)).array;

			// relevant history
			_trainingcache.relevantHistory = db.execute("
				SELECT time, group_concat(sequence, '') as sequence, _timestamp
				FROM (
					SELECT datetime(_timestamp/1000, 'unixepoch') as time, _timestamp, group_concat(f3, '') as sequence
					FROM tf_table
					WHERE (_timestamp, trim(f3, ' ')) NOT IN (
						SELECT _timestamp, f5
						FROM d_table
					)
					GROUP BY time, f4
					ORDER BY _timestamp, f2
				)
				GROUP BY _timestamp
			").map!((r) {
				TrainingCache.Info info;
				info.time = r["time"].as!string;
				info.sequence = r["sequence"].as!string;
				info.timestamp = r["_timestamp"].as!size_t;
				return info;
			}).array;
		}
		else
		{
			import std.format : format;
			import gboardforensics.analysis : FailedAnalysisException;
			throw new FailedAnalysisException(format!"Not yet implemented for database '%s'!"(_trainingcache.path.baseName()));
		}
	}

	@property const(TrainingCache) trainingcache() const
	{
		return _trainingcache;
	}

	protected DBVERSION _dbversion;
	protected TrainingCache _trainingcache;
}
