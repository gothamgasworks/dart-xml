library xml.test.builder_test;

import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'assertions.dart';

void main() {
  test('basic', () {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.processing('xml-stylesheet',
        'href="/style.css" type="text/css" title="default stylesheet"');
    builder.element('bookstore', nest: () {
      builder.comment('Only one book?');
      builder.element('book', nest: () {
        builder.element('title', nest: () {
          builder.attribute('lang', 'en');
          builder.text('Harry ');
          builder.cdata('Potter');
        });
        builder.element('price', nest: 29.99);
      });
    });
    final xml = builder.build();
    assertTreeInvariants(xml);
    final actual = xml.toString();
    final expected = '<?xml version="1.0" encoding="UTF-8"?>'
        '<?xml-stylesheet href="/style.css" type="text/css" title="default stylesheet"?>'
        '<bookstore>'
        '<!--Only one book?-->'
        '<book>'
        '<title lang="en">Harry <![CDATA[Potter]]></title>'
        '<price>29.99</price>'
        '</book>'
        '</bookstore>';
    expect(actual, expected);
  });
  test('all', () {
    final builder = XmlBuilder();
    builder.processing('processing', 'instruction');
    builder.element('element1', attributes: {'attribute1': 'value1'}, nest: () {
      builder.attribute('attribute2', 'value2',
          attributeType: XmlAttributeType.DOUBLE_QUOTE);
      builder.attribute('attribute3', 'value3',
          attributeType: XmlAttributeType.SINGLE_QUOTE);
      builder.element('element2');
      builder.comment('comment');
      builder.cdata('cdata');
      builder.text('textual');
    });
    final xml = builder.build();
    assertTreeInvariants(xml);
    final actual = xml.toString();
    final expected = '<?processing instruction?>'
        '<element1 attribute1="value1" attribute2="value2" attribute3=\'value3\'>'
        '<element2/>'
        '<!--comment-->'
        '<![CDATA[cdata]]>'
        'textual'
        '</element1>';
    expect(actual, expected);
  });
  test('self-closing', () {
    final builder = XmlBuilder();
    builder.element('element', nest: () {
      builder.element('self-closing-default');
      builder.element('self-closing-true', isSelfClosing: true);
      builder.element('self-closing-true-with-children',
          isSelfClosing: true, nest: '!');
      builder.element('self-closing-false', isSelfClosing: false);
    });
    final xml = builder.build();
    assertTreeInvariants(xml);
    final actual = xml.toString();
    final expected = '<element>'
        '<self-closing-default/>'
        '<self-closing-true/>'
        '<self-closing-true-with-children>!</self-closing-true-with-children>'
        '<self-closing-false></self-closing-false>'
        '</element>';
    expect(actual, expected);
  });
  test('nested string', () {
    final builder = XmlBuilder();
    builder.element('element', nest: 'string');
    final xml = builder.build();
    assertTreeInvariants(xml);
    final actual = xml.toString();
    final expected = '<element>string</element>';
    expect(actual, expected);
  });
  test('nested iterable', () {
    final builder = XmlBuilder();
    builder.element('element', nest: [
      () => builder.text('st'),
      'ri',
      ['n', 'g']
    ]);
    final xml = builder.build();
    assertTreeInvariants(xml);
    final actual = xml.toString();
    final expected = '<element>string</element>';
    expect(actual, expected);
  });
  test('nested node (element)', () {
    final builder = XmlBuilder();
    final nested = XmlElement(XmlName('nested'));
    builder.element('element', nest: nested);
    final xml = builder.build();
    assertTreeInvariants(xml);
    expect(xml.children[0].children[0].toXmlString(), nested.toXmlString());
    expect(xml.children[0].children[0], isNot(same(nested)));
    final actual = xml.toString();
    final expected = '<element><nested/></element>';
    expect(actual, expected);
  });
  test('nested node (element, repeated)', () {
    final builder = XmlBuilder();
    final nested = XmlElement(XmlName('nested'));
    builder.element('element', nest: [nested, nested]);
    final xml = builder.build();
    assertTreeInvariants(xml);
    expect(xml.children[0].children[0].toXmlString(), nested.toXmlString());
    expect(xml.children[0].children[0], isNot(same(nested)));
    expect(xml.children[0].children[1].toXmlString(), nested.toXmlString());
    expect(xml.children[0].children[1], isNot(same(nested)));
    final actual = xml.toString();
    final expected = '<element><nested/><nested/></element>';
    expect(actual, expected);
  });
  test('nested node (text)', () {
    final builder = XmlBuilder();
    final nested = XmlText('text');
    builder.element('element', nest: nested);
    final xml = builder.build();
    assertTreeInvariants(xml);
    expect(xml.children[0].children[0].toXmlString(), nested.toXmlString());
    expect(xml.children[0].children[0], isNot(same(nested)));
    final actual = xml.toString();
    final expected = '<element>text</element>';
    expect(actual, expected);
  });
  test('nested node (text, repeated)', () {
    final builder = XmlBuilder();
    final nested = XmlText('text');
    builder.element('element', nest: [nested, nested]);
    final xml = builder.build();
    assertTreeInvariants(xml);
    expect(xml.children[0].children[0].text, 'texttext');
    expect(xml.children[0].children[0], isNot(same(nested)));
    final actual = xml.toString();
    final expected = '<element>texttext</element>';
    expect(actual, expected);
  });
  test('nested node (data)', () {
    final builder = XmlBuilder();
    final nested = XmlComment('abc');
    builder.element('element', nest: nested);
    final xml = builder.build();
    assertTreeInvariants(xml);
    expect(xml.children[0].children[0].toXmlString(), nested.toXmlString());
    expect(xml.children[0].children[0], isNot(same(nested)));
    final actual = xml.toString();
    final expected = '<element><!--abc--></element>';
    expect(actual, expected);
  });
  test('nested node (attribute)', () {
    final builder = XmlBuilder();
    final nested = XmlAttribute(XmlName('foo'), 'bar');
    builder.element('element', nest: nested);
    final xml = builder.build();
    assertTreeInvariants(xml);
    expect(xml.children[0].attributes[0].toXmlString(), nested.toXmlString());
    expect(xml.children[0].attributes[0], isNot(same(nested)));
    final actual = xml.toString();
    final expected = '<element foo="bar"/>';
    expect(actual, expected);
  });
  test('nested node (document)', () {
    final builder = XmlBuilder();
    final nested = XmlDocument([]);
    expect(() => builder.element('element', nest: nested), throwsArgumentError);
  });
  test('nested node (document fragment)', () {
    final builder = XmlBuilder();
    final nested = XmlDocumentFragment([XmlText('foo'), XmlComment('bar')]);
    builder.element('element', nest: nested);
    final xml = builder.build();
    assertTreeInvariants(xml);
    expect(xml.children[0].children[0].toXmlString(),
        nested.children[0].toXmlString());
    expect(xml.children[0].children[0], isNot(same(nested.children[0])));
    expect(xml.children[0].children[1].toXmlString(),
        nested.children[1].toXmlString());
    expect(xml.children[0].children[1], isNot(same(nested.children[1])));
    final actual = xml.toString();
    final expected = '<element>foo<!--bar--></element>';
    expect(actual, expected);
  });
  test('invalid attributes', () {
    final builder = XmlBuilder();
    expect(() => builder.attribute('key', 'value'), throwsArgumentError);
  });
  test('text', () {
    final builder = XmlBuilder();
    builder.element('text', nest: () {
      builder.text('abc');
      builder.text('');
      builder.text('def');
    });
    final xml = builder.build();
    assertTreeInvariants(xml);
    final actual = xml.toString();
    final expected = '<text>abcdef</text>';
    expect(actual, expected);
  });
  test('namespace binding', () {
    final uri = 'http://www.w3.org/2001/XMLSchema';
    final builder = XmlBuilder();
    builder.element('schema', nest: () {
      builder.namespace(uri, 'xsd');
      builder.attribute('lang', 'en', namespace: uri);
      builder.element('element', namespace: uri);
    }, namespace: uri);
    final xml = builder.build();
    assertTreeInvariants(xml);
    final actual = xml.toString();
    final expected =
        '<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" xsd:lang="en">'
        '<xsd:element/>'
        '</xsd:schema>';
    expect(actual, expected);
  });
  test('default namespace binding', () {
    final uri = 'http://www.w3.org/2001/XMLSchema';
    final builder = XmlBuilder();
    builder.element('schema', nest: () {
      builder.namespace(uri);
      builder.attribute('lang', 'en', namespace: uri);
      builder.element('element', namespace: uri);
    }, namespace: uri);
    final xml = builder.build();
    assertTreeInvariants(xml);
    final actual = xml.toString();
    final expected =
        '<schema xmlns="http://www.w3.org/2001/XMLSchema" lang="en">'
        '<element/>'
        '</schema>';
    expect(actual, expected);
  });
  test('undefined namespace', () {
    final builder = XmlBuilder();
    expect(() => builder.element('element', namespace: 'http://1.foo.com/'),
        throwsArgumentError);
  });
  test('invalid namespace', () {
    final builder = XmlBuilder();
    builder.element('element', nest: () {
      expect(() => builder.namespace('http://1.foo.com/', 'xml'),
          throwsArgumentError);
      expect(() => builder.namespace('http://2.foo.com/', 'xmlns'),
          throwsArgumentError);
    });
    final actual = builder.build().toString();
    final expected = '<element/>';
    expect(actual, expected);
  });
  test('conflicting namespace', () {
    final builder = XmlBuilder();
    builder.element('element', nest: () {
      builder.namespace('http://1.foo.com/', 'foo');
      expect(() => builder.namespace('http://2.foo.com/', 'foo'),
          throwsArgumentError);
    }, namespace: 'http://1.foo.com/');
    final actual = builder.build().toString();
    final expected = '<foo:element xmlns:foo="http://1.foo.com/"/>';
    expect(actual, expected);
  });
  test('unused namespace', () {
    final builder = XmlBuilder();
    builder.element('element', nest: () {
      builder.namespace('http://1.foo.com/', 'foo');
    });
    final actual = builder.build().toString();
    final expected = '<element xmlns:foo="http://1.foo.com/"/>';
    expect(actual, expected);
  });
  test('unused namespace (optimized)', () {
    final builder = XmlBuilder(optimizeNamespaces: true);
    builder.element('element', nest: () {
      builder.namespace('http://1.foo.com/', 'foo');
    });
    final actual = builder.build().toString();
    final expected = '<element/>';
    expect(actual, expected);
  });
  test('duplicate namespace', () {
    final builder = XmlBuilder();
    builder.element('element', nest: () {
      builder.namespace('http://1.foo.com/', 'foo');
      builder.element('outer', nest: () {
        builder.namespace('http://1.foo.com/', 'foo');
        builder.element('inner', nest: () {
          builder.namespace('http://1.foo.com/', 'foo');
          builder.attribute('lang', 'en', namespace: 'http://1.foo.com/');
        });
      });
    });
    final actual = builder.build().toString();
    final expected = '<element xmlns:foo="http://1.foo.com/">'
        '<outer xmlns:foo="http://1.foo.com/">'
        '<inner xmlns:foo="http://1.foo.com/" foo:lang="en"/>'
        '</outer>'
        '</element>';
    expect(actual, expected);
  });
  test('duplicate namespace on attribute (optimized)', () {
    final builder = XmlBuilder(optimizeNamespaces: true);
    builder.element('element', nest: () {
      builder.namespace('http://1.foo.com/', 'foo');
      builder.element('outer', nest: () {
        builder.namespace('http://1.foo.com/', 'foo');
        builder.element('inner', nest: () {
          builder.namespace('http://1.foo.com/', 'foo');
          builder.attribute('lang', 'en', namespace: 'http://1.foo.com/');
        });
      });
    });
    final actual = builder.build().toString();
    final expected = '<element xmlns:foo="http://1.foo.com/">'
        '<outer>'
        '<inner foo:lang="en"/>'
        '</outer>'
        '</element>';
    expect(actual, expected);
  });
  test('duplicate namespace on element (optimized)', () {
    final builder = XmlBuilder(optimizeNamespaces: true);
    builder.element('element', nest: () {
      builder.namespace('http://1.foo.com/', 'foo');
      builder.element('outer', nest: () {
        builder.namespace('http://1.foo.com/', 'foo');
        builder.element('inner', namespace: 'http://1.foo.com/');
      });
    });
    final actual = builder.build().toString();
    final expected = '<element xmlns:foo="http://1.foo.com/">'
        '<outer>'
        '<foo:inner/>'
        '</outer>'
        '</element>';
    expect(actual, expected);
  });
  test('entities cdata escape', () {
    final builder = XmlBuilder();
    builder.element('element', nest: '<test><![CDATA[string]]></test>');
    final xml = builder.build();
    assertTreeInvariants(xml);
    final actual = xml.toString();
    final expected =
        '<element>&lt;test>&lt;![CDATA[string]]&gt;&lt;/test></element>';
    expect(actual, expected);
  });
}
