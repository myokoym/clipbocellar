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

require "gtk2"
require "clipcellar/tree_view"
require "clipcellar/clipboard"
require "clipcellar/command"

module Clipcellar
  class Window < Gtk::Window
    attr_accessor :text
    def initialize(records)
      super()
      @records = records
      self.title = "Clipcellar"
      set_default_size(640, 480)
      signal_connect("destroy") do
        Gtk.main_quit
      end

      @vbox = Gtk::VBox.new
      add(@vbox)

      @scrolled_window = Gtk::ScrolledWindow.new
      @scrolled_window.set_policy(:automatic, :automatic)
      @vbox.pack_start(@scrolled_window, true, true, 0)

      @tree_view = TreeView.new(records)
      @scrolled_window.add(@tree_view)

      @label = Gtk::Label.new
      @label.text = "Double Click or Press Return: Copy to Clipboard / Ctrl+d: Delete from Data Store"
      @vbox.pack_start(@label, false, false, 0)

      @tree_view.signal_connect("row-activated") do |tree_view, path, column|
        Clipboard.copy_to_clipboard(@tree_view.selected_text)
      end

      define_key_bindings
    end

    def run
      show_all
      Gtk.main
    end

    private
    def define_key_bindings
      signal_connect("key-press-event") do |widget, event|
        handled = false

        if event.state.control_mask?
          handled = action_from_keyval_with_control_mask(event.keyval)
        else
          handled = action_from_keyval(event.keyval)
        end

        handled
      end
    end

    def action_from_keyval(keyval)
      case keyval
      when Gdk::Keyval::GDK_KEY_n
        @tree_view.next
      when Gdk::Keyval::GDK_KEY_p
        @tree_view.prev
      when Gdk::Keyval::GDK_KEY_Return
        Clipboard.copy_to_clipboard(@tree_view.selected_text)
      when Gdk::Keyval::GDK_KEY_h
        @scrolled_window.hadjustment.value -= 17
      when Gdk::Keyval::GDK_KEY_j
        @scrolled_window.vadjustment.value += 17
      when Gdk::Keyval::GDK_KEY_k
        @scrolled_window.vadjustment.value -= 17
      when Gdk::Keyval::GDK_KEY_l
        @scrolled_window.hadjustment.value += 17
      when Gdk::Keyval::GDK_KEY_q
        destroy
      else
        return false
      end
      true
    end

    def action_from_keyval_with_control_mask(keyval)
      case keyval
      when Gdk::Keyval::GDK_KEY_n
        10.times { @tree_view.next }
      when Gdk::Keyval::GDK_KEY_p
        10.times { @tree_view.prev }
      when Gdk::Keyval::GDK_KEY_d
        key = @tree_view.selected_key
        if key
          # TODO: don't want to use Command class.
          GroongaDatabase.new.open(Command.new.database_dir) do |database|
            database.delete(key)
          end
          @tree_view.remove_selected_record
        end
      else
        return false
      end
      true
    end

    def clipboard
      Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
    end
  end
end
