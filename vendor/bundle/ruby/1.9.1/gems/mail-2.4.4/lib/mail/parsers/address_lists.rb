# Autogenerated from a Treetop grammar. Edits may be lost.


module Mail
  module AddressLists
    include Treetop::Runtime

    def root
      @root ||= :primary_address
    end

    include RFC2822

    module PrimaryAddress0
      def addresses
        ([first_addr] + other_addr.elements.map { |o| o.addr_value }).reject { |e| e.empty? }
      end
    end

    module PrimaryAddress1
      def addresses
        [first_addr] + other_addr.elements.map { |o| o.addr_value }
      end
    end

    def _nt_primary_address
      start_index = index
      if node_cache[:primary_address].has_key?(index)
        cached = node_cache[:primary_address][index]
        if cached
          cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
          @index = cached.interval.end
        end
        return cached
      end

      i0 = index
      r1 = _nt_address_list
      r1.extend(PrimaryAddress0)
      if r1
        r0 = r1
      else
        r2 = _nt_obs_addr_list
        r2.extend(PrimaryAddress1)
        if r2
          r0 = r2
        else
          @index = i0
          r0 = nil
        end
      end

      node_cache[:primary_address][start_index] = r0

      r0
    end

  end

  class AddressListsParser < Treetop::Runtime::CompiledParser
    include AddressLists
  end

end
