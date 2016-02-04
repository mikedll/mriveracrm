
require 'spec_helper'

describe Page do
  context "rendering" do
    before :each do
      @page = FactoryGirl.create(:page)
    end

    it "should convert markdown as needed" do
      @page.body = "# Good Neighbors

This was a decent movie.

I liked it. I liked it a lot. It reminded me of things that happened to me a long time ago.

I look forward to any possible sequel.

"
      @page.compiled_body.should == "\n"
      @page.save
      @page.compiled_body.should == "<h1 id=\"good-neighbors\">Good Neighbors</h1>\n\n<p>This was a decent movie.</p>\n\n<p>I liked it. I liked it a lot. It reminded me of things that happened to me a long time ago.</p>\n\n<p>I look forward to any possible sequel.</p>\n\n"
    end
  end
end
