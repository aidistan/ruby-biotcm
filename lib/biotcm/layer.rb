require 'biotcm/table'
require 'fileutils'

module BioTCM
  # A basic data model representing one layer, containing one node table and
  # one edge table.
  #
  # = Usage
  # Load a layer
  #
  #   layer = BioTCM::Layer.load('co-occurrence')
  #   #   co-occurrence/node.tab
  #   #   co-occurrence/edge.tab
  #
  #   layer = BioTCM::Layer.load('co-occurrence', prefix: '[20150405]')
  #   #   co-occurrence/[20150405]node.tab
  #   #   co-occurrence/[20150405]edge.tab
  #
  # Save the layer
  #
  #   layer.save('co-occurrence', prefix: '[20150405]')
  #   #   co-occurrence/[20150405]node.tab
  #   #   co-occurrence/[20150405]edge.tab
  #
  class Layer
    # Version
    VERSION = '0.1.0'

    # Table of nodes
    # @return [Table]
    attr_reader :node_tab
    # Table of edges
    # @return [Table]
    attr_reader :edge_tab

    # Load a layer from disk
    # @param path [String]
    # @param colname [Hash] A hash for column name mapping
    # @return [Layer]
    def self.load(path = nil, prefix: '',
      colname: {
        source: 'Source',
        target: 'Target',
        interaction: nil
      }
    )
      # Path convention
      if path
        edge_path = File.expand_path(prefix + 'edge.tab', path)
        node_path = File.expand_path(prefix + 'node.tab', path)
      end
      fin = File.open(edge_path)
      # Headline
      col = fin.gets.chomp.split("\t")
      unless (i_src = col.index(colname[:source]))
        fail ArgumentError, "Cannot find source node column: #{colname[:source]}"
      end
      unless (i_tgt = col.index(colname[:target]))
        fail ArgumentError, "Cannot find target node column: #{colname[:target]}"
      end
      col[i_src] = col[i_tgt] = nil
      if colname[:interaction]
        unless (i_typ = col.index(colname[:interaction]))
          fail ArgumentError, "Cannot find interaction type column: #{colname[:interaction]}"
        end
        col[i_typ] = nil
      else
        i_typ = nil
      end
      col.compact!
      # Initialize members
      node_tab = Table.new
      edge_tab = Table.new(primary_key: [colname[:source], colname[:interaction], colname[:target]].compact.join("\t"), col_keys: col)
      # Load edge_file
      node_in_table = node_tab.instance_variable_get(:@row_keys)
      col_size = edge_tab.col_keys.size
      fin.each do |line|
        col = line.chomp.split("\t")
        src = col[i_src]
        tgt = col[i_tgt]
        typ = i_typ ? col[i_typ] : nil
        # Insert nodes
        node_tab.row(src, []) unless node_in_table[src]
        node_tab.row(tgt, []) unless node_in_table[tgt]
        # Insert edge
        col[i_src] = col[i_tgt] = nil
        col[i_typ] = nil if i_typ
        col.compact!
        fail ArgumentError, "Row size inconsistent in line #{fin.lineno + 2}" unless col.size == col_size
        edge_tab.row([src, typ, tgt].compact.join("\t"), col)
      end
      # Load node_file
      if node_path
        tab = Table.load(node_path)
        node_tab.primary_key = tab.primary_key
        node_tab = node_tab.merge(tab)
      end

      new(edge_tab: edge_tab, node_tab: node_tab)
    end

    #
    def initialize(edge_tab: nil, node_tab: nil)
      @edge_tab = edge_tab || Table.new(primary_key: 'Edge')
      @node_tab = node_tab || Table.new(primary_key: 'Node')
    end
    # Save the layer to disk
    def save(path, prefix = '')
      FileUtils.mkdir_p(path)
      @edge_tab.save(File.expand_path(prefix + 'edge.tab', path))
      @node_tab.save(File.expand_path(prefix + 'node.tab', path))
    end
  end
end