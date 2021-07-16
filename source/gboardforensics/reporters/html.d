/**
 * This module represents the HTML output reporter
 *
 * Authors: João Lourenço, Luís Ferreira
 * Copyright: João Lourenço (c) 2021
 *            Luís Ferreira (c) 2021
 * License: GPL-3.0
 */
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

		const AnalysisData data = this.data;

		auto dst = appender!string();
		dst.compileHTMLDietFile!("report.dt",
			data
		);

		return dst[];
	}
}
