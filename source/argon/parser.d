module argon.parser;

import std.string;
import std.array;
import std.uni;

import argon.ast;

ASTTemplateNode parseArgonTemplate(string file, string source)
{
	auto state = new ParserState(file, source.replace("\r\n", "\n"));
	auto node = new ASTTemplateNode;
	state.parent = node;
	node.file = file;

	node.children = parseArgonNodes(state);

	state.parent = node.parent;
	return node;
}

ASTHTMLNode parseArgonHTML(ParserState state)
{
	Appender!(string) html;
	auto node = new ASTHTMLNode;
	node.parent = state.parent;

	while(!state.testFor("{include=") && !state.testFor("{element=") && !state.testFor("{list=") && !state.testFor("{/list}") && state.remaining > 0)
	{
		html.put(state.pop());
	}

	if (state.testFor("{include="))
	{
		auto lines = html.data.splitLines;
		lines[$-1] = lines[$-1].stripRight;
		node.html = lines.join("\n");
	}
	else
		node.html = html.data.stripRight;
	return node;
}

ASTIncludeNode parseArgonInclude(ParserState state)
{
	auto node = new ASTIncludeNode;
	node.parent = state.parent;

	state.expect("{include=");
	node.file = parseString(state);
	state.expect("}");

	return node;
}

ASTElementNode parseArgonElement(ParserState state)
{
	auto node = new ASTElementNode;
	node.parent = state.parent;
	state.parent = node;

	state.expect("{element=");
	node.identifier = parseArgonIdentifier(state);
	state.expect("}");

	state.parent = node.parent;
	return node;
}

ASTListNode parseArgonList(ParserState state)
{
	auto node = new ASTListNode;
	node.parent = state.parent;
	state.parent = node;

	state.expect("{list=");
	node.identifier = parseArgonIdentifier(state);
	state.expect("}");
	//state.pos += state.source[state.pos..$].length-state.source[state.pos..$].stripLeft().length;

	node.children = parseArgonNodes(state, "{/list}");
	state.expect("{/list}");
	state.parent = node.parent;
	return node;
}

ASTIdentifierNode parseArgonIdentifier(ParserState state)
{
	auto node = new ASTIdentifierNode;
	node.parent = state.parent;
	node.callChain.length = 1;

	while(state.peek().isAlphaNum() || state.peek() == '_')
		node.namespace ~= state.pop();
	state.expect(":");
	while(state.peek().isAlphaNum() || state.peek() == '_')
	{
		node.callChain[$-1] ~= state.pop();
		if (state.peek() == '.')
		{
			state.pop();
			node.callChain.length++;
		}
		else if (state.peek == '[')
		{
			node.callChain.length++;
			state.pop();
			node.callChain[$-1] ~= "[" ~ state.peek() ~ "]";
			if (state.peek != '#')
				state.expect("$");
			else
				state.pop();
			state.expect("]");
		}
	}
	
	return node;
}

ASTNode[] parseArgonNodes(ParserState state, string stopString = null)
{
	ASTNode[] children;
	for(auto child = parseArgonNode(state, stopString); child !is null; child = parseArgonNode(state, stopString))
		children ~= child;
	return children;
}

ASTNode parseArgonNode(ParserState state, string stopString = null)
{
	if ((stopString !is null && state.testFor(stopString)) || state.remaining == 0)
		return null;
	else if (state.testFor("{include="))
		return parseArgonInclude(state);
	else if (state.testFor("{element="))
		return parseArgonElement(state);
	else if (state.testFor("{list="))
		return parseArgonList(state);
	else
		return parseArgonHTML(state);
}

string parseString(ParserState state)
{
	state.expect(`"`);
	Appender!string str;
	while(state.peek() != '"')
	{
		str.put(state.pop());
	}
	state.expect(`"`);
	return str.data;
}

class ParserState
{
	size_t line = 1, colunm;
	string file;

	size_t pos;
	string source;
	ASTNode parent;

	this(string file, string source)
	{
		this.file = file;
		this.source = source;
	}

	bool testFor(string test)
	{
		return source.length >= pos + test.length && source[pos..pos+test.length] == test;
	}

	void advance(size_t count = 1)
	{
		if (pos+count > source.length)
			throw new ArgonParserException("Unexpected end of file", getSourceLocation());
		foreach(i; 0..count)
		{
			if (peek == '\n')
			{
				colunm = 0;
				line++;
			}
			else
			{
				colunm++;
			}
			pos++;
		}
	}

	void expect(string str)
	{
		if (!testFor(str))
			throw new ArgonParserException("Expected "~str, getSourceLocation());
		advance(str.length);
	}

	char peek()
	{
		return source[pos];
	}

	char pop()
	{
		char c = peek();
		advance();
		return c;
	}

	SourceLocation getSourceLocation()
	{
		return new SourceLocation(file, line, colunm);
	}

	@property size_t remaining()
	{
		return source.length - pos;
	}
}

class ArgonParserException : Exception
{
	this(string msg, SourceLocation sourceLocation, string file = __FILE__, size_t line = __LINE__)
	{
		super(msg ~ ' ' ~ sourceLocation.getErrorMessage(), file, line);
	}
}