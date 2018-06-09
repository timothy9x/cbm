#!/usr/bin/ruby
# Final podcast url: http://www.cbmministry.org/podcast.rss

require 'fileutils'
require 'date'
require 'optparse'
require 'mp3info'
#require_relative 'cbm_podcast'

$search_order='19609'	# search_order for the message to be posted


#     ____            __                __
#    / __ \____  ____/ /________ ______/ /_
#   / /_/ / __ \/ __  / ___/ __ `/ ___/ __/
#  / ____/ /_/ / /_/ / /__/ /_/ (__  ) /_
# /_/    \____/\__,_/\___/\__,_/____/\__/
#

module Podcast
  # https://github.com/boncey/ruby-podcast
  # - using RSS 2.0, it works for itune

  def Podcast.raw_input(prompt="")
    print prompt
    gets.strip
  end

  def Podcast.mp3tag(nl)
    Mp3Info.open(nl) do |mp3|
      puts "================================="
      puts "This part is to modify the ID3 tag on the mp3 files."
      puts "the mp3 file to be tagged is: "+nl
      puts "----"*8
      otitle, oartist, oalbum=(mp3.tag.title or " "), (mp3.tag.artist or " " ), (mp3.tag.album or " ")
      puts "if you would like to change the tag, please input the right info. Otherwise, the old info will be kept."

      title=Podcast.raw_input("title was: "+otitle+" change to: ")
      artist=Podcast.raw_input("artist was: "+oartist+ " change to: ")
      ablum=Podcast.raw_input("album was: "+oalbum+ " change to: ")

      title=otitle if title==""
      artist=oartist if artist==""
      album=oalbum if album==""

      mp3.tag.title=title
      mp3.tag.artist=artist
      mp3.tag.album=album
    end
  end

  def Podcast.check(locationList)
    puts "\n\n Now we are checking the mp3 tag info of the files:\n"
    locationList.each do |location|
      Dir.chdir(location)
      Dir.glob('*.mp3').each do |fn|
        puts fn
        Mp3Info.open(fn) do |mp3|
          otitle, oartist, oalbum=(mp3.tag.title or " "),
    (mp3.tag.artist or " " ), (mp3.tag.album or " ")
          # puts otitle+";"+oartist+";"+ oalbum
          if otitle==" " then
            return false
          end
        end
      end
    end
    true
  end

  def Podcast.check_and_fix(locationList)
    puts "\n\n Now we are checking the mp3 tag info of the files:\n"
    locationList.each do |location|
      Dir.chdir(location)
      Dir.glob('*.mp3').each do |fn|
        puts fn
        Mp3Info.open(fn) do |mp3|
          otitle, oartist, oalbum=(mp3.tag.title or " "),
		    (mp3.tag.artist or " " ), (mp3.tag.album or " ")
          if otitle==" " then
            Podcast.mp3tag(fn)
          end
        end
      end
    end
  end

  def Podcast.podcast(locationList)
    # Generate podcast based on each folder in locationList
    abspath_len = "/home2/cbmnyus/public_html/cbmministry/".length
    backup_count = 0

    locationList.each do |location|
      backup_count = backup_count + 1

      # Debug - here we actually need the full/absolute path for the location
      puts location
      Dir.chdir(location)
      location=Dir.pwd

	    base_url="http://www.cbmministry.org/" + location[abspath_len..-1]
	    base_url= base_url[0..-2] if base_url.end_with?("/") # Remove trailing /

      podcast_command="podcast -d ./ -o ~/bin/current_month_podcast.rss -t 'CBM Messages' -e 'CBM Messages' -l http://www.cbmministry.org/podcasts.rss -i 'fish.jpg' -b #{base_url} -v 2.0"
      puts "Generating podcast with the following command:"
      puts podcast_command
      puts "----------------------------------------------"
      system(podcast_command)

      # After generating current month podcast rss, copy it www folder
      FileUtils.cp('/home2/cbmnyus/bin/current_month_podcast.rss', '/home2/cbmnyus/public_html/cbmministry/current_month_podcast.rss')
      # Make backup for the previous podcasts.rss [for rolling back if errors]
      FileUtils.cp('/home2/cbmnyus/public_html/cbmministry/podcasts.rss', '/home2/cbmnyus/public_html/cbmministry/podcasts_backup' + backup_count.to_s + '.rss')

      # Take the current podcast content - from beginning to the first item
      # TODO: this needs revision - so that multiple items can be added
      #       Currently it takes the first 25 lines of newly generated podcast
      #       Then, use the first 25 lines, append onto the top of old podcast.rss
      #       Solutions:
                  # Perhaps we can add a new parameter to this function (generate podcast), to indicate how many new podcast we will add to.
                  # Alternatively (better): we create or delve into the podcast.class; and see how to extract the title/file name of each podcast, and only those newly processed audio files? or files don't exist in the current podcasts, get written in the new/final podcast.

      current_podcast_file=File.open('/home2/cbmnyus/public_html/cbmministry/current_month_podcast.rss')
      current_podcast_content=current_podcast_file.to_a
      current_podcast_file.close
      current_podcast_content=current_podcast_content[0..25]

      # Take all previous content - except the beginning header, all the rest content
      previous_podcast_file=File.open('/home2/cbmnyus/public_html/cbmministry/podcasts.rss')
      previous_podcast_content=previous_podcast_file.to_a
      previous_podcast_file.close
      previous_podcast_content=previous_podcast_content[17..-1]

      # write the updated contacted content together
      podcast_file=File.open('/home2/cbmnyus/public_html/cbmministry/podcasts.rss', 'w')
      # current_podcast_content.each {|l| podcast_file.write(l)}
      current_podcast_content[0..16].each {|l| podcast_file.write(l)}
      podcast_file.write("    <itunes:explicit>no</itunes:explicit>\n")
      podcast_file.write("    <category>Religion &amp; Spirituality</category>\n")
      current_podcast_content[17..25].each {|l| podcast_file.write(l)}
      previous_podcast_content.each {|l| podcast_file.write(l)}
      podcast_file.close
    end # End of the location list

  end

end # End of Podcast Module

#     ______                 __  _
#    / ____/_  ______  _____/ /_(_)___  ____  _____
#   / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
#  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
# /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

def raw_input(prompt="")
  print prompt
  gets.strip
end


def confirm(input)
# Similar as raw_input but return true/false based on the answer
  puts input+":\n \t\t (y/yes as confirmed, others are not confirmed)"
  s=gets.strip.downcase
  if s=="y" or s=="yes"
    return true
  else
    return false
  end
end

def valid_date?(str, format="%Y-%m-%d")
  Date.strptime(str, format) rescue false
end

def rename(name_array)
# Rename each files in the input array, return final renamed files list
  list=[]
  name_array.each do |f|
    nfn=raw_input("Rename "+f+" as: ")
    if nfn!=""
      File.rename(f, nfn)
      list.push(nfn)
    end
  end
  list
end

def audio_file_compress(fn, output_fn)
# Compress fn to new_fn (filename)
  compress_command="lame -a -V 9 -b 8 --resample 11.025 "
  new_fn=output_fn || ("compessed_"+fn)
  if File.exist? new_fn
    return new_fn
  else
    command_to_execute=compress_command+"'"+fn+"'"+' '+new_fn
    system command_to_execute
    puts fn + "is compressed as "+ new_fn
  end
  new_fn
end

def compress_specific_audio_file(fn)
# Compress the audio file provided (fn) in the same folder
# with new file name inputed from the user
  if !File.exist? fn
    puts "Could not find the input file: ", fn
  else
    output_fn=raw_input("Please enter the new compressed file name:")
    if File.exist? output_fn
      puts "The file already exists, please try a different name next time."
      exit(1)
    else
      audio_file_compress(fn, output_fn)
    end
  end
  output_fn
end

def compress_lastWeek
# Compress audio files uploaded, return the list of files compressed

  # oldList is orginal file list, newList is the output/compressed
  oldList, newList=[],[]

  # Generate list of files uploaded in the last 2 weeks
  Dir.chdir('/home2/cbmnyus/public_html/cbmministry/audioUpload')
  Dir.glob(['*.mp3', '*.wav']).each do |fn|
    puts fn
    if (Time.now-File.mtime(fn))<=7*60*60*24*2 # uploaded wthin 2 weeks
      oldList.push(fn)
    else
      puts 'There is no audio file uploaded in the past 2 weeks.'
    end
  end

  # Renaming each comoressed file
  oldList.each do |fn|
    newList.push(raw_input("Please enter compressed name (use By to seperate speadker, such as Y-m-d_Message_By_Bro_Dana_Congdon.mp3) \n\t for: "+fn+" as :"))
  end
  finalList=newList.dup
  puts "oldList, finalList", oldList, finalList

  # Actual Compression work
  oldList.reverse.each { |fn| audio_file_compress(fn, finalList.pop) }

  #Return the file name list dictionary for renaming files
  return oldList, newList
end

def archive(old_list, new_list)
# move each file in the old list to new_path, concated with new list name
# path=new_path
	path= '/home2/cbmnyus/public_html/cbmministry/audioUpload/previous'

  for i in 0..(old_list.length-1)
  	f=old_list[i]
  	dfn=new_list[i]
  	dest= path + "/" + f.split(".")[0] + "_"+dfn
  	# puts f, path, dest
    FileUtils.move f, dest
  end
end

def mv_to_rightFolder(name_array)
# to move the right mp3 files to the proper folder accoding to the data sturcture for php files
  msgPath='/home2/cbmnyus/public_html/cbmministry/MP3/Messages'

  new_location_list=[]
  name_array.each do | fn|
    mp3tag(fn)
    # move each files in the lists
    datePart=valid_date?(fn[0..9])

    if datePart
      yearPart=datePart.year.to_s
      monthPart=datePart.strftime("%B")
      newLocation=msgPath+"/"+yearPart+"/"+monthPart+"_"+yearPart+"/"

      $year=yearPart
      $month=monthPart

      # checking if destination dir exists, if not, create one
      if !File.directory?(newLocation)
        puts newLocation + " doesn't exist, is created now."
        FileUtils.mkdir_p(newLocation)
      end

      begin
        FileUtils.move fn, newLocation
        puts "processed file is successfully moved to the new location."
        new_location_list.push(newLocation)
      rescue
        puts "files could not be moved to :" + newLocation
        puts "operation is aborted!"
        exit(1)
      end
    else
      puts "the processed file " + fn+ "lacks the proper date string yyyy-mm-dd, abort(1)"
      exit(1)
    end
  end
  new_location_list.uniq # return the new location list
end

def mp3tag(file_name)
# Add correct mp3 tag to the file
  Mp3Info.open(file_name) do |mp3|
    puts "================================="
    puts "This part is to modify the ID3 tag on the mp3 files."
    puts "the mp3 file to be tagged is: "+file_name
    puts "----"*8
    otitle, oartist, oalbum=(mp3.tag.title or " "), (mp3.tag.artist or " " ), (mp3.tag.album or " ")
    puts "if you would like to change the tag, please input the right info. Otherwise, the old info will be kept."

    title=raw_input("title was: "+otitle+" change to: ")
    artist=raw_input("artist was: "+oartist+ " change to: ")
    ablum=raw_input("album was: "+oalbum+ " change to: ")

    title=otitle if title==""
    artist=oartist if artist==""
    album=oalbum if album==""

    mp3.tag.title=title
    mp3.tag.artist=artist
    mp3.tag.album=album
  end
end

def post(fn)
# Generate the post sql entry for the file name given
  search_order=$search_order
  category='Messages'

  if $year.nil? || $month.nil?
    $year=raw_input("Please enter the message year:")
    $month=raw_input("Please enter the message month:")
  end

  subcategory=$year
  subcategory2=$month+" "+ $year
  title=""
  speaker=""

  Mp3Info.open(fn) do |mp3|
   title=mp3.tag.title or raw_input("Please enter message title:")
   speaker=mp3.tag.artist or raw_input("please enter speaker's name:")
  end

  venue="CBM"
  file_name=fn
  scriptures=raw_input("Please enter scriptures:")
  date_delivered=fn[0..9]

  def q(a)
    astr=a || ""
    "\'"+astr+"\'"
  end

  a=[search_order, category, subcategory, subcategory2, title, speaker, venue, file_name,scriptures , date_delivered]
  a.map! {|i| q(i) }
  search_order, category, subcategory, subcategory2, title, speaker, venue, file_name, scriptures, date_delivered=a

  template=" insert into message (id, category, subcategory, subcategory2, title, speaker, venue, file_name, length, scriptures, num_copies, date_delivered, search_order) VALUES (NULL, #{category}, #{subcategory}, #{subcategory2}, #{title}, #{speaker}, #{venue}, #{file_name},NULL, #{scriptures}, NULL, #{date_delivered}, #{search_order}); "

  puts "============================================"
  puts "the file name fn is:", fn
  puts "the sql template generated is:", template
  puts "============================================"

  return template+"\n"
end

def gen_post_folder(folder)
# Generate sql from a given folder
  # Go through the mp3 file in the folder, if selected yes, then generate the sql
  # If there's no such folder, return -1
  # If folder exsits, the result SQL file is generated at ~/bin/final.sql

    final_sql_content=""
    if Dir.exist?(folder)
      Dir.chdir(folder)
    else
      puts "There's no such folder: " + folder
      return -1
    end

    Dir.glob('*.mp3').each do |fn|
      if confirm("Add " + fn + " to the generated sql ?")
          final_sql_content+= post(fn)
      end
    end

    # DEBUG
    puts final_sql_content

    # Copy/Backup the exisint final.sql to final+date.sql
    current_date_str=Date.today.to_s
    final_sql_date_path="/home2/cbmnyus/bin/final_backup_" + current_date_str+".sql"
    FileUtils.cp("/home2/cbmnyus/bin/final.sql", final_sql_date_path)

    File.open("/home2/cbmnyus/bin/final.sql", "w") { |f| f.write(final_sql_content) }
    puts "successfully generated final.sql file."
end

def gen_podcast_folder(folder)
# Generate podcast.rss from a given folder
  # Check if the folder exist, if yes:
  # Generate podcast from the files in the folder to standard location

  final_sql_content=""
  if Dir.exist?(folder)
    Podcast.podcast([folder])
  else
    puts "There's no such folder: " + folder
    return -1
  end

end

#     __  ___      _          __                _
#    /  |/  /___ _(_)___     / /   ____  ____ _(_)____
#   / /|_/ / __ `/ / __ \   / /   / __ \/ __ `/ / ___/
#  / /  / / /_/ / / / / /  / /___/ /_/ / /_/ / /jj /__
# /_/  /_/\__,_/_/_/ /_/  /_____/\____/\__, /_/\___/
#                                     /____/

def usage(opts)
  puts 'weekly.rb --options directory ...'
  puts opts.help
  exit
end

def main
# Main logic of parsing options and executions
  def call_compress_last_week
    # call function compress_lastWeek,
    # return new_location list, and new file list: new_list
    puts "======================================"
    puts "CBM Weekly audio posting script"
    puts "last 3 month calendar is:"
    system "cal -3"
    puts "======================================"
    puts " Checking audioUpload/ for mp3 files:"

    # =======================================
    # Section to compress the audio files, and move the correct month
    old_list, new_list = compress_lastWeek
    puts new_list
    archive(old_list, new_list)

    puts new_list # Print out before moving to the right folder
    new_location_list=mv_to_rightFolder(new_list)
    return new_location_list, new_list
  end

  def generate_final_sql(new_location_list, new_list)
    # =======================================
    # Section to generate the proper sql files for inserting into the table
    # Section to genrate the right sql commands
    final_sql_content=""

    # new_location_list is the folder location of the new folder moved to
    # new_list is the list of files that is processed (new file names)
    list_count=0
    new_location_list.each do | new_location |
      Dir.chdir(new_location)
      new_list.each do |nlf|
        if File.exist?(nlf) then
            puts "the new file exsits:", nlf
            final_sql_content+= post(nlf)
        end
      end
    end
    puts final_sql_content
    FileUtils.cp("/home2/cbmnyus/bin/final.sql","/home2/cbmnyus/bin/final.sql_backup" )
    File.open("/home2/cbmnyus/bin/final.sql", "w") { |f| f.write(final_sql_content) }
    puts "successfully generated final.sql file.\n\n"
  end

  def generate_podcast(podcast_dir)
    # =======================================
    # Section to generate podcast files
    #TODO: revise podcast here to take the title and album info from
    #above or don't process the tag information here
    # -- sometimes there are issues in generating rss when no mp3 tag info
    # Podcast.podcast(new_location_list) -- this line is the old code

    if podcast_dir.kind_of?(Array)
      Podcast.podcast( podcast_dir )
    else
      Podcast.podcast([podcast_dir])
    end
  end

  options={:action=>nil, :path=>nil}
  optparse=OptionParser.new do |opts|
    opts.banner= "Usage: weekly.rb [options] [option_path]"

    opts.on("-c", "--compress file", "file-to-be-compressed") do |file|
      options[:action]=:compress
      options[:path]=file
    end

    opts.on("-t", "--tag file_path", "mp3-file-to-be-tagged") do |file_path|
      options[:action]=:mp3tag
      options[:path]=file_path
    end

    opts.on("-s", "--sql folder", "directory_to_generate_sql") do |folder|
      options[:action] = :genSql
      options[:path]=folder
    end

    opts.on("-p", "--podcast folder", "folder_to_generate_podcast") do |folder|
      options[:action] = :podCast
      options[:path]=folder
    end

    opts.on("-w", "--weekly", "generate sql from last 2 weeks") do
      options[:action] = :lastWeek
    end

    opts.on("-h", "--help", 'Display this screen') do
      puts opts
      exit
    end
  end

  optparse.parse!

  # Dispatch/actual execution of program functions
  case options[:action]
    when :lastWeek
        new_location_list, new_list = call_compress_last_week
        generate_final_sql(new_location_list, new_list)
        generate_podcast(new_location_list)
    when :compress
      puts options[:path]
      compress_specific_audio_file(options[:path])
    when :mp3tag
      mp3tag(options[:path])
    when :genSql
      gen_post_folder(options[:path])
    when :podCast
      gen_podcast_folder(options[:path])
    else
      puts "There are no such options!"
      puts optparse.help
  end

end # End of main logic

# Final call for main function (python style call)
if __FILE__==$0
	main()
end
i
