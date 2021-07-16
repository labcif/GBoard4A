/**
 * This module represents the JSON output reporter
 *
 * Authors: João Lourenço, Luís Ferreira
 * Copyright: João Lourenço (c) 2021
 *            Luís Ferreira (c) 2021
 * License: GPL-3.0
 */
module gboardforensics.reporters.json;

import asdf.serialization;

import gboardforensics.reporters;
import gboardforensics.analysis;

/**
 * Represents an analysis result reporter for JSON format
 */
class JsonReporter : Reporter
{
	///
	@safe pure nothrow
	public this(AnalysisData data)
	{
		super(data);
	}

	///
	pure
	public override string toString() const
	{
		return data.serializeToJsonPretty!();
	}
}

///
pure
unittest
{
	AnalysisData data;
	data.rootPath = "foobar";

	auto reporter = new JsonReporter(data);
	assert(reporter.toString() == `{
	"rootPath": "foobar",
	"dictionaries": [

	],
	"trainingcache": [

	],
	"clipboard": [

	],
	"expressionHistory": [

	],
	"translateCache": [

	]
}`);
}
