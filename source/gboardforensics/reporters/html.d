module gboardforensics.reporters.html;

import std.datetime;

import asdf.serialization;

import gboardforensics.reporters;
import gboardforensics.analysis;

/**
 * Represents an analysis result reporter for HTML format
 */
class HTMLReporter : Reporter
{
	///
	@safe pure nothrow
	public this(AnalysisData data)
	{
		super(data);
	}

	///
	public override string toString() const
	{
		import std.array : appender;
		import diet.html : compileHTMLDietFile;

		// explicit mutable copy of data
		AnalysisData data = this.data;

		auto dst = appender!string();
		dst.compileHTMLDietFile!("report.dt",
			data
		);

		return dst[];
	}
}
