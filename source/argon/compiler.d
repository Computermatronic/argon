module argon.compiler;

import std.array;
import std.format;
import std.typecons;
import std.conv;

import argon.ast;
import argon.parser;

template renderArgonTemplate(string file, Args...)
{
	auto renderArgonTemplate(Writer)(auto ref Writer writer)
	{
		static if (__traits(compiles, writer.bodyWriter))
		{
			auto output = writer.bodyWriter;
		}
		else
		{
			auto output = writer;
		}
		
		enum mainTemplate = compileArgonTemplate!file();
		enum includeTemplates = compileArgonIncludeTemplates!(mainTemplate[1])() ~ mainTemplate;

		void delegate()[string] file_table;

		auto get_namespace(string namespace)()
		{
			static foreach(i, Arg; Args)
				static if (__traits(compiles, Arg == namespace) && Arg == namespace)
					return Args[i+1];
		}

		auto register_file(string fileName)(void delegate() func)
		{
			file_table[fileName] = func;
		}

		auto do_file(string fileName)()
		{
			file_table[fileName]();
		}

		static foreach(includeTemplate; includeTemplates)
		{
			mixin(includeTemplate[0]);
		}

		do_file!file();
	}
}

private alias ArgonTemplate = Tuple!(string, string[]);

private ArgonTemplate compileArgonTemplate(string file)()
{
	auto compiler = new ArgonCompiler(file, import(file));
	return tuple(compiler.source, compiler.includeFiles);
}

private ArgonTemplate[] compileArgonIncludeTemplates(string[] files)()
{
	ArgonTemplate[] templates;
	static foreach(i, file; files)
	{
		mixin(format(q{
			enum template_%s = compileArgonTemplate!file();
			templates ~= template_%s ~ compileArgonIncludeTemplates!(template_%s[1])();
			}, i, i, i));
	}
	return templates;
}

final class ArgonCompiler : ASTVisitor
{
	string file;
	string[] includeFiles;
	ASTTemplateNode templateAST;

	private Appender!string output;
	private size_t[string] listElementDict;
	private size_t lastUniqueId;

	this(string file, string source)
	{
		this.file = file;
		templateAST = parseArgonTemplate(file, source);
		templateAST.accept(this);
	}

	void visit(ASTTemplateNode node)
	{
		auto functionId = node.file.hashOf();
		output.formattedWrite("void template_%s()\n{\n", functionId);
		foreach(child; node.children)
		{
			child.accept(this);
		}
		output.formattedWrite("}\nregister_file!(`%s`)(&template_%s);\n\n", this.file, functionId);
	}

	void visit(ASTHTMLNode node)
	{
		output.formattedWrite("output.write(`%s`);\n", node.html.replace("`", "` ~ '`' ~ `"));
	}

	void visit(ASTIncludeNode node)
	{
		includeFiles ~= node.file;
		output.formattedWrite("do_file!(`%s`)();\n", node.file);
	}

	void visit(ASTElementNode node)
	{
		output.put("output.write(text(");
		node.identifier.accept(this);
		output.put("));\n");
	}

	void visit(ASTListNode node)
	{
		auto idString = format("%s:%-(%s.%)", node.identifier.namespace, node.identifier.callChain);
		listElementDict[idString] = uniqueId;
		output.formattedWrite("foreach(list_%s, element_%s; ", listElementDict[idString], listElementDict[idString]);
		node.identifier.accept(this);
		output.put(")\n{\n");
		foreach(child; node.children)
		{
			child.accept(this);
		}
		output.put("}\n");
	}

	void visit(ASTIdentifierNode node)
	{
		Appender!string identifier;

		identifier.formattedWrite("get_namespace!(`%s`)()", node.namespace);
		foreach(i, call; node.callChain)
		{
			if (call == "[$]")
			{
				auto idString = format("%s:%-(%s.%)", node.namespace, node.callChain[0..i]);
				identifier.formattedWrite("[list_%s]", listElementDict[idString]);
			}
			else if (call == "[#]")
			{
				auto idString = format("%s:%-(%s.%)", node.namespace, node.callChain[0..i]);
				identifier = Appender!string.init;
				identifier.formattedWrite("list_%s", listElementDict[idString]);
			}
			else
			{
				identifier.formattedWrite(".%s", call);
			}
		}
		output.put(identifier.data);
	}

	@property string source()
	{
		return output.data;
	}

	@property size_t uniqueId()
	{
		return lastUniqueId++;
	}
}