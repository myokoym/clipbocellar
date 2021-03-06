# Copyright (C) 2014  Masafumi Yokoyama <myokoym@gmail.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

module Clipcellar
  class GroongaSearcher
    class << self
      def search(database, words, options)
        clipboards = database.clipboards
        selected_clipboards = clipboards.select do |clipboard|
          expression = nil
          words.each do |word|
            sub_expression = (clipboard.text =~ word)
            if expression.nil?
              expression = sub_expression
            else
              expression &= sub_expression
            end
          end

          if options[:mtime]
            base_date = (Time.now - (options[:mtime] * 60 * 60 * 24))
            mtime_expression = clipboard.date > base_date
            if expression.nil?
              expression = mtime_expression
            else
              expression &= mtime_expression
            end
          end

          expression
        end

        order = options[:reverse] ? "descending" : "ascending"
        sorted_clipboards = selected_clipboards.sort([{
                                                        :key => "created_at",
                                                        :order => order,
                                                      }])

        sorted_clipboards
      end
    end
  end
end
