#!/usr/bin/ruby

$:.unshift( "../lib" );
require "graphviz"

GraphViz::new( "G" ) { |g|
  g.hello << g.world
  g.bonjour( :label => '"Bonjour"' ) - g.monde( :label => "Le\nmonde")
  g.hola > g.mundo
  g.holla >> g.welt
}.output( :path => "/usr/local/bin", :png => "#{$0}.png" )
