import std.stdio;
import std.variant;

import argon.compiler;

void main()
{
	enum file = "test2.argon";
	Writer w;
	w.renderArgonTemplate!(Writer, file, "content", Test());
	//auto argonTemplate = parseArgonTemplate(file, import(file));
	//argonTemplate.accept(new Printer);
	//writeln(new ArgonCompiler(file, import(file)).source);
}

struct Test
{
	string hello_world = "Hello, World!";
	string[] test_list = ["a", "b", "c"];
}

struct Writer
{
	void write(string str)
	{
		stdout.write(str);
	}
}

//class Printer : ASTVisitor
//{
//	void visit(ASTTemplateNode node)
//	{
//		writeln('#', node.file);
//		foreach(child; node.children)
//			child.accept(this);
//	}

//	void visit(ASTHTMLNode node)
//	{
//		writeln(node.html);
//	}

//	void visit(ASTIncludeNode node)
//	{
//		writefln(`{include="%s"}`, node.file);
//	}

//	void visit(ASTElementNode node)
//	{
//		write(`{element=`);
//		node.identifier.accept(this);
//		writeln(`}`);
//	}

//	void visit(ASTListNode node)
//	{
//		write(`{list=`);
//		node.identifier.accept(this);
//		writeln(`}`);

//		foreach(child; node.children)
//			child.accept(this);
//		writeln(`{/list}`);
//	}

//	void visit(ASTIdentifierNode node)
//	{
//		writef(`%s:%-(%s.%)`, node.namespace, node.callChain);
//	}
//}