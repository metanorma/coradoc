require "spec_helper"
require "awesome_print"

RSpec.describe Coradoc::Parser::Markdown::BlockParser do
  describe ".parse" do
    it "parses the markdown to standard doc" do
      puts 'parsing'
      document = subject.parse_with_debug(%q(

  test first
paragraph
     
    then second

#

jaja

---

## h2h2h2 hihihi
####h4h4h4h

 **  * ** * ** * **


    def owo():
      pass

# h1 test ##########

> one quote
> 
> with two pgs
>
> # and an h1
>  -     -      -      -
> 
>> extra
> > owo
>>
> > extra2nd
>>
>>> 3rd level
>>> 
> back to upper quote
> woohoo
> 

      ))
      ap document
    end
  end
end

