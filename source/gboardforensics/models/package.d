module gboardforensics.models;

public
{
	import gboardforensics.models.dictionary;
	import gboardforensics.models.trainingcache;
	import gboardforensics.models.clipboard;
	import gboardforensics.models.expressionhistory;
}

import std.traits : ReturnType;

/// Whether a model is countable or not
enum bool isCountableModel(T) =
	is(typeof(T.init) == T)
	&& is(ReturnType!((T t) => t.countItems) == size_t);

///
unittest
{
	struct Foo {}
	assert(isCountableModel!Dictionary);
	assert(isCountableModel!TrainingCache);
	assert(!isCountableModel!Foo);
}

/**
 * Calculates the number of total items inside an array of
 * countable models.
 *
 * Returns: number of total items
 */
@safe pure nothrow
size_t countItems(T)(T[] items)
	if(isCountableModel!T)
{
	import std.algorithm.iteration : map, sum;
	import std.array : array;

	return items.map!"a.countItems".sum;
}

///
@safe pure nothrow
unittest
{
	Dictionary[] dict = [
		Dictionary("foo", [
			Dictionary.Entry("foo", "f", "en-US"),
			Dictionary.Entry("bar", "b", "en-US")
		]),
		Dictionary("foobar", [
			Dictionary.Entry("foo", "f", "en-US"),
			Dictionary.Entry("bar", "b", "en-US")
		])
	];

	assert(dict.countItems() == 4);
}
