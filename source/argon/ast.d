module argon.ast;

import std.format;

interface ASTVisitor
{
	void visit(ASTTemplateNode node);
	void visit(ASTHTMLNode node);
	void visit(ASTIncludeNode node);
	void visit(ASTElementNode node);
	void visit(ASTListNode node);
	void visit(ASTIdentifierNode node);
}

class ASTTemplateNode : ASTNode
{
	string file;
	ASTNode[] children;

	override void accept(ASTVisitor visitor)
	{
		visitor.visit(this);
	}
}

class ASTHTMLNode : ASTNode
{
	string html;

	override void accept(ASTVisitor visitor)
	{
		visitor.visit(this);
	}
}

class ASTIncludeNode : ASTNode
{
	string file;

	override void accept(ASTVisitor visitor)
	{
		visitor.visit(this);
	}
}

class ASTElementNode : ASTNode
{
	ASTIdentifierNode identifier;

	override void accept(ASTVisitor visitor)
	{
		visitor.visit(this);
	}
}

class ASTListNode : ASTNode
{
	ASTIdentifierNode identifier;
	ASTNode[] children;

	override void accept(ASTVisitor visitor)
	{
		visitor.visit(this);
	}
}

class ASTIdentifierNode : ASTNode
{
	string namespace;
	string[] callChain;

	override void accept(ASTVisitor visitor)
	{
		visitor.visit(this);
	}
}

abstract class ASTNode
{
	ASTNode parent;
	SourceLocation sourceLocation;

	abstract void accept(ASTVisitor visitor);
}


class SourceLocation
{
	size_t colunm, line;
	string file;

	this(string file, size_t line, size_t colunm)
	{
		this.file = file;
		this.line = line;
		this.colunm = colunm;
	}

	string getErrorMessage()
	{
		return format("at line %s, colunm %s, in file '%s'", line, colunm, file);
	}
}