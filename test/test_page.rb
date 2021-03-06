# ~*~ encoding: utf-8 ~*~
require File.join(File.dirname(__FILE__), *%w[helper])

context "Page" do
  setup do
    @wiki = Gollum::Wiki.new(testpath("examples/lotr.git"))
  end

  test "new page" do
    page = Gollum::Page.new(@wiki)
    assert_nil page.raw_data
    assert_nil page.formatted_data
  end

  test "get existing page" do
    page = @wiki.page('Bilbo Baggins')
    assert_equal Gollum::Page, page.class
    assert page.raw_data =~ /^# Bilbo Baggins\n\nBilbo Baggins/
    assert page.formatted_data =~ /<h1>Bilbo Baggins<\/h1>\n\n<p>Bilbo Baggins/
    assert_equal 'Bilbo-Baggins.md', page.path
    assert_equal :markdown, page.format
    assert_equal @wiki.repo.commits.first.id, page.version.id
  end

  test "get existing page case insensitive" do
    assert_equal @wiki.page('Bilbo Baggins').path, @wiki.page('bilbo baggins').path
  end

  test "get nested page" do
    page = @wiki.page('Eye Of Sauron')
    assert_equal 'Mordor/Eye-Of-Sauron.md', page.path
  end

  test "page versions" do
    page = @wiki.page('Bilbo Baggins')
    assert_equal ["f25eccd98e9b667f9e22946f3e2f945378b8a72d", "5bc1aaec6149e854078f1d0f8b71933bbc6c2e43"],
      page.versions.map { |v| v.id }
  end

  test "page versions across renames" do
    page = @wiki.page 'My-Precious'
    assert_equal ['60f12f4254f58801b9ee7db7bca5fa8aeefaa56b', '94523d7ae48aeba575099dd12926420d8fd0425d'],
      page.versions(:follow => true).map { |v| v.id }
  end

  test "page versions without renames" do
    page = @wiki.page 'My-Precious'
    assert_equal ['60f12f4254f58801b9ee7db7bca5fa8aeefaa56b'],
      page.versions(:follow => false).map { |v| v.id }
  end

  test "specific page version" do
    page = @wiki.page('Bilbo Baggins', 'fbabba862dfa7ac35b39042dd4ad780c9f67b8cb')
    assert_equal 'fbabba862dfa7ac35b39042dd4ad780c9f67b8cb', page.version.id
  end

  test "no page match" do
    assert_nil @wiki.page('I do not exist')
  end

  test "no version match" do
    assert_nil @wiki.page('Bilbo Baggins', 'I do not exist')
  end

  test "no ext match" do
    assert_nil @wiki.page('Data')
  end

  test "cname" do
    assert_equal "Foo", Gollum::Page.cname("Foo")
    assert_equal "Foo-Bar", Gollum::Page.cname("Foo Bar")
    assert_equal "Foo---Bar", Gollum::Page.cname("Foo / Bar")
    assert_equal "José", Gollum::Page.cname("José")
    assert_equal "モルドール", Gollum::Page.cname("モルドール")
  end

  test "title from filename with normal contents" do
    page = @wiki.page('Bilbo Baggins')
    assert_equal 'Bilbo Baggins', page.title
  end

  test "title from filename with html contents" do
    page = @wiki.page('My <b>Precious', '0ed8cbe0a25235bd867e65193c7d837c66b328ef')
    assert_equal 'My Precious', page.title
  end

  test "title from h1 with normal contents" do
    page = @wiki.page('Home')
    assert_equal "The LOTR Wiki", page.title
  end

  test "title from h1 with html contents" do
    page = @wiki.page('Eye Of Sauron')
    assert_equal "Eye Of Sauron", page.title
  end

  test "top level footer" do
    footer = @wiki.page('Home').footer
    assert_equal 'Lord of the Rings wiki', footer.raw_data
    assert_equal '_Footer.md', footer.path
  end

  test "nested footer" do
    footer = @wiki.page('Eye Of Sauron').footer
    assert_equal "Ones does not simply **walk** into Mordor!\n", footer.raw_data
    assert_equal "Mordor/_Footer.md", footer.path
  end

  test "footer itself" do
    footer = @wiki.page("_Footer")
    assert_nil footer.footer
  end

  test "cannot convert non string to human readable page title" do
    assert_equal '', Gollum::Page.cname(nil)
    assert_equal '', Gollum::Page.cname(3)
  end
end
